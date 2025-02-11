
import pandas as pd
import pyreadstat
import os
from functools import reduce
from sklearn.model_selection import train_test_split


### Functions
## Function: combine all useful columns into one column of a predictor dataset
def process_dataset(
    input_dta_path,
    cols_to_drop,
    combined_column_name,
):
    # Step 1: Load the .dta file and extract the data and metadata
    df, meta = pyreadstat.read_dta(input_dta_path) 

    # Step 2: Process each variable except ID
    # Create a dictionary mapping column names to their labels
    column_labels_dict = dict(zip(df.columns, meta.column_labels))
    df = df[df.columns.drop(list(df.filter(regex='|'.join(cols_to_drop))))]
    # Update meta.column_labels based on the remaining columns
    meta.column_labels = [column_labels_dict[col] for col in df.columns]

    # Create a function to process the value labels and append variable labels
    def process_value(val, value_labels, var_label):
        # Handle NaN values
        if pd.isna(val):
            return val
        # Check if value labels exist for the variable and map the numeric value to the label
        if value_labels and val in value_labels:
            label = value_labels[val]
            # Append the variable label to the value label
            return f"{var_label}: {label}"
        else:
            return f"{var_label}: {val}"

    # Iterate through all columns except the ID column
    for col in df.columns:
        if col != 'mergeid':
            # Get the index of the current column
            col_index = df.columns.get_loc(col)
            # Get the variable label (if it exists)
            var_label = meta.column_labels[col_index] if col_index < len(meta.column_labels) else ''
            # Get the value labels for the current column (if they exist)
            value_labels = meta.variable_value_labels.get(col, None)
            # Apply the process to the column
            df[col] = df[col].apply(lambda x: process_value(x, value_labels, var_label))

    # Step 3: Create a new column with concatenated values of all columns (except ID)
    # The values will be joined with a newline ('\n') to separate them by row
    df[combined_column_name] = df.drop(columns=['mergeid']).apply(lambda row: '\n'.join(row.dropna().astype(str)), axis=1)
    df = df[['mergeid', combined_column_name]]
    return df



### Define common parameters
base_dir = "/Users/yifei/Desktop/share_data/"
waves = [1, 2, 4, 5, 6, 7]
common_cols_to_drop = ['^hhid', '^mergeidp', '^coupleid', 'language']

# Define predictor dataset-specific configurations
datasets_info = [
    {
        "suffix": "ph",
        "additional_cols_to_drop": ['ph003_'],
        "combined_column_name": "physical_health"
    },
    {
        "suffix": "br",
        "additional_cols_to_drop": ['country'],
        "combined_column_name": "behavioral_risk"
    },
    {
        "suffix": "dn",
        "additional_cols_to_drop": ['country', '^dn012d', '^dn023d'],
        "combined_column_name": "demographics_networks"
    },
    {
        "suffix": "hc",
        "additional_cols_to_drop": ['country'],
        "combined_column_name": "health_care"
    },
    {
        "suffix": "gv_health",
        "additional_cols_to_drop": ['country', 'sphus', 'sphus2'],
        "combined_column_name": "generated_health"
    }
]



### Main code
## Generate the full dataset for each wave
all_merged_dfs = [] 
for wave in waves:

    base_suffix = f"w{wave}"
    mortality_suffix = f"w{wave+2}"

    # Process each predictor dataset
    processed_dfs = []
    for info in datasets_info:
        additional_cols_to_drop = info.get("additional_cols_to_drop", [])
        processed_df = process_dataset(
            input_dta_path=os.path.join(base_dir, f"share{base_suffix}_rel9-0-0_ALL_datasets_stata/share{base_suffix}_rel9-0-0_{info['suffix']}.dta"),
            cols_to_drop=common_cols_to_drop + additional_cols_to_drop,
            combined_column_name=info["combined_column_name"],
        )
        if processed_df is not None:
            processed_dfs.append(processed_df)

    # Merge all processed predictor datasets
    if processed_dfs:
        merged_df = reduce(lambda left, right: pd.merge(left, right, on='mergeid', how='outer'), processed_dfs)
        for col in merged_df.columns:
            if col != 'mergeid':
                merged_df[col] = merged_df[col].apply(lambda x: f"{col}:\n{x}")
        merged_df['text'] = merged_df.drop(columns=['mergeid']).apply(lambda row: '\n\n'.join(row.dropna().astype(str)), axis=1)
        merged_df = merged_df[['mergeid', 'text']]

    # Merge the merged predictor dataset with variable deceased from wave i+2
    df_mo, meta_mo = pyreadstat.read_dta(os.path.join(base_dir, f"share{mortality_suffix}_rel9-0-0_ALL_datasets_stata/share{mortality_suffix}_rel9-0-0_cv_r.dta")) 
    df_mo = df_mo[['mergeid', 'deceased']]
    merged_mo = merged_df.merge(df_mo, on='mergeid')
    merged_mo = merged_mo.rename(columns={'mergeid': 'id'})
    merged_mo['wave'] = wave
    all_merged_dfs.append(merged_mo)

# Concatenate all waves into a single DataFrame
final_df = pd.concat(all_merged_dfs, ignore_index=True)
final_df = final_df[['id', 'wave', 'text', 'deceased']]
final_df = final_df.sort_values(by=['id', 'wave']).reset_index(drop=True)
final_df.to_csv(os.path.join(base_dir, "all_waves_mp.csv"), index=False)



## Generate train, validation and test datasets
# Target variable
X = final_df.drop(['deceased'], axis=1)
y = final_df['deceased']

# First split: Training and temporary sets
X_train, X_temp, y_train, y_temp = train_test_split(
    X, y, test_size=0.30, random_state=42, stratify=y)
# Second split: Validation and test sets
X_val, X_test, y_val, y_test = train_test_split(
    X_temp, y_temp, test_size=0.6667, random_state=42, stratify=y_temp)

# Combine features and target for each split
train_df = pd.concat([X_train, y_train], axis=1)
val_df = pd.concat([X_val, y_val], axis=1)
test_df = pd.concat([X_test, y_test], axis=1)

# Save the splitted datasets
train_df.to_csv(os.path.join(base_dir, f"mp_train.csv"), index=False)
val_df.to_csv(os.path.join(base_dir, f"mp_validation.csv"), index=False)
test_df.to_csv(os.path.join(base_dir, f"mp_test.csv"), index=False)

# Count the number of 1 and verify the splits
count = (final_df['deceased'] == 1).sum()
percentage = (count / len(final_df['deceased'])) * 100
print(f"Number of 1's: {count}")
print(f"Percentage of 1's: {percentage:.2f}%")
print(f"Total samples: {len(final_df)}")
print(f"Training set size: {len(train_df)} ({len(train_df)/len(final_df)*100:.2f}%)")
print(f"Validation set size: {len(val_df)} ({len(val_df)/len(final_df)*100:.2f}%)")
print(f"Test set size: {len(test_df)} ({len(test_df)/len(final_df)*100:.2f}%)")


