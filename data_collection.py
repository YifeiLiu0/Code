
## Preparation

import os
import re
from pypdf import PdfReader
from habanero import Crossref
import pandas as pd

# define paths
base_path = "C:/Users/一飞/Desktop/Yifei/Data/Data Porcessing/Variables Statistics/SHARE_Publications"
ori_path = os.path.join(base_path, "original")



## Functions

# function: extract all DOIs from PDF files to a txt file
def pdf2doi(original_path, doi_file_path):

    # if "doi.txt" exists, return the existing file directly
    if os.path.exists(doi_file_path):
        return
    
    # if not exist, create a new one
    doi_file = open(doi_file_path, 'w')
    # define DOI regular expression (to match DOIs in the files)
    doi_pattern = re.compile(r"10.\d{2,9}/[-._;()/:A-Z0-9]+(?=\s|\.|$)", re.IGNORECASE)

    # check if the path exists and it is a directory
    if os.path.exists(original_path) and os.path.isdir(original_path):

        # extract all DOIs in each PDF file
        for filename in os.listdir(original_path):

            # check if the file is a PDF
            if filename.endswith('.pdf'):
                
                # create a empty list (to store all the extracted DOIs)
                file_dois = []
                # create the full path to the PDF file
                pdf_path = os.path.join(original_path, filename)
                
                # try opening the PDF file and extracting its content
                try:
                    reader = PdfReader(pdf_path)

                    # iterate through all the pages in the PDF document
                    for page_num in range(len(reader.pages)):
                        # access each individual page by its number
                        page = reader.pages[page_num]
                        # extract the text from the current page
                        text = page.extract_text()
                        # remove all whitespace characters (like spaces, tabs, or newlines)
                        text = re.sub(r'\s+', '', text)
                        # search for all DOIs within the current page
                        matches = doi_pattern.finditer(text)

                        # store all DOI matches in the all_dois list
                        for match in matches:
                            # remove all contents after ".Abstract" of the extracted content
                            doi = match.group().split('.Abstract')[0]
                            # remove the final dot if exists
                            doi = doi[:-1] if doi.endswith(".") else doi
                            # append all cleaned DOIs together
                            file_dois.append(doi)

                    ## define the format of "doi.txt"
                    # add the source (pdf file) to DOIs for tracking
                    doi_file.write(f"filename: {filename}\n")
                    # make every DOI appears in its own line
                    for fd in file_dois:
                        doi_file.write(fd + "\n")
                    # add a blank line between different files
                    doi_file.write('\n')

                except Exception as e:
                    print(f"An error occurred while processing the file {filename}: {str(e)}")
    else:
        print("The provided path does not exist or is not a directory.")

    # if created before, then need to be closed
    doi_file.close()



# function: convert doi to dataframe
def doi2dict(doi):

    cr = Crossref()
    try:
        entry = cr.works(ids=doi)
    except:
        return None
    
    msg = entry.get('message')
    dct = {'title_org': msg.get('title')[0],
       'relevant_pages': msg.get('page'), 
       'date_month': msg.get('created').get('date-parts')[0][1],
       'date_year': msg.get('created').get('date-parts')[0][0],
       'publisher': msg.get('publisher'),
       'permanent_identifier': msg.get('DOI'),
       'type': msg.get('type').replace('-', ' '), # other types than journal-article
       'periodical': msg.get('container-title')[0] if msg.get('container-title') else '',
       'number': msg.get('issue')
    }

    authors = msg.get('author')
    if authors:
        for i in range(min(25, len(authors))):
            author = authors[i]
            if author.get('affiliation'):
                aff = author.get('affiliation')[0].get('name')
                dct[f'author{i+1}_affiliation'] = aff.split(',')[0].strip()
                dct[f'author{i+1}_affiliation_country'] = aff.split(',')[-1].strip()

            dct[f'author{i+1}_forename'] = author.get('given')
            dct[f'author{i+1}_surname'] = author.get('family')

    return dct



# function: convert doi to csv
def doi2csv(doi_file_path, csv_file_path):
    if os.path.exists(csv_file_path):
        return
    
    dicts = []
    # read DOIs from the file
    try:
        with open(doi_file_path, 'r') as doi_file:
            for line in doi_file:
                stripped_line = line.strip()
                if stripped_line.startswith('10'):
                    dct = doi2dict(stripped_line)
                    if dct:
                        dicts.append(dct)
                    else:
                        print(stripped_line)

    except Exception as e:
        print(f"An error occurred while reading the DOIs: {e}")
        return
    
    df = pd.DataFrame(dicts)
    df.to_csv(csv_file_path, index=False)



# order the csv file
def csv_order(csv_file_path):
    df = pd.read_csv(csv_file_path)

    # add title_eng column
    df.insert(df.columns.get_loc('title_org') + 1, 'title_eng', '')

    # add author_country columns
    for i in range(1, 26):
        for column_suffix in ['forename', 'surname', 'country', 'affiliation', 'affiliation_country']:
            column_name = f'author{i}_{column_suffix}'
            if column_name not in df.columns:
                df[column_name] = None 

    # order columns
    base_columns = ['title_org', 'title_eng', 'type', 'periodical', 'number', 'date_month', 
                    'date_year', 'relevant_pages', 'permanent_identifier', 'publisher']

    author_columns = []
    for i in range(1, 26):
        author_columns.extend([
            f'author{i}_forename', 
            f'author{i}_surname', 
            f'author{i}_country', 
            f'author{i}_affiliation', 
            f'author{i}_affiliation_country'
        ])

    ordered_columns = base_columns + [col for col in author_columns if col in df.columns]
    df = df[ordered_columns]

    # save updates
    df.to_csv(csv_file_path, index=False)



## Main Code

if __name__ == "__main__":

    # define file paths
    doi_file_path = os.path.join(base_path, "doi_hanting.txt")
    csv_file_path = os.path.join(base_path, "doi_hanting.csv")

    # call functions
    pdf2doi(ori_path, doi_file_path)
    doi2csv(doi_file_path, csv_file_path)
    csv_order(csv_file_path)
    
