import os
import csv
from pathlib import Path


def add_columns_to_csv(input_path: Path, output_path: Path, new_headers, 
                       listCreateOrChangeSQLJobsMaintPlans, 
                       listCreateOrChangeTriggersSPsTables, 
                       listCreateUsersOrChangeAccess, 
                       listPerformOrAlterBackupsAndRestores):
    output_path.parent.mkdir(parents=True, exist_ok=True)

    header = ['Server', 'Database', 'User/Role', 'Type', 'Privilege', 'Category']

    with input_path.open(newline='', encoding='utf-8-sig') as inf, \
            output_path.open('w', newline='', encoding='utf-8') as outf:
        reader = csv.reader(inf)
        writer = csv.writer(outf)

        header_out = header + new_headers
        writer.writerow(header_out)

        for row in reader:
            if len(row) < len(header):
                row = row + [''] * (len(header) - len(row))
            row_out = row + [''] * len(new_headers)

            if len(row) > 4:
                user_role = row[2].lower()
                privilege = row[4].lower()
                
                if any(item in user_role or item in privilege for item in listCreateOrChangeSQLJobsMaintPlans):
                    row_out[6] = 'yes'

                if any(item in user_role or item in privilege for item in listCreateOrChangeTriggersSPsTables):
                    row_out[7] = 'yes'

                if any(item in user_role or item in privilege for item in listCreateUsersOrChangeAccess):
                    row_out[8] = 'yes'

                if any(item in user_role or item in privilege for item in listPerformOrAlterBackupsAndRestores):
                    row_out[9] = 'yes'

            writer.writerow(row_out)
            
def main():
    cwd = Path(os.getcwd())
    input_dir = cwd / 'Input'
    output_dir = cwd / 'Output'
    input_dir.mkdir(exist_ok=True)
    output_dir.mkdir(exist_ok=True)

    new_headers = ['Create or Change SQL Jobs / Maint Plans', 'Create or Change Triggers, SPs, Tables', 'Create Users or Change Access', 'Perform or Alter Backups and Restores']

    listCreateOrChangeSQLJobsMaintPlans = [
        'sysadmin',
        'SQLAgentOperatorRole',
        'SQLAgentAdminRole',
        'SQLAgentUserRole'
    ]
    
    listCreateOrChangeTriggersSPsTables = [
        'sysadmin',
        'db_owner', 
        'db_ddladmin',
        'CREATE TABLE',
        'ALTER',
        'CREATE PROCEDURE',
        'ALTER ANY PROCEDURE',
        'CREATE TRIGGER',
        'ALTER ANY TRIGGER',
        'CONTROL on schema'
    ]
    
    listCreateUsersOrChangeAccess = [
        'sysadmin',
        'securityadmin',
        'db_owner',
        'db_securityadmin',
        'ALTER ANY LOGIN',
        'CREATE LOGIN',
        'ALTER ANY USER',
        'CREATE USER',
        'ALTER ROLE',
        'CONTROL on database'
    ]
    
    listPerformOrAlterBackupsAndRestores = [
        'sysadmin',
        'dbcreator',
        'db_backupoperator',
        'db_owner',
        'BACKUP DATABASE',
        'RESTORE LOG',
        'RESTORE DATABASE'
    ]

    csv_files = list(input_dir.glob('*.csv'))
    if not csv_files:
        print('No CSV files found in Input. Place .csv files into the Input folder and re-run.')
        print(input_dir)
        return

    print(f'Processing {input_dir} -> {output_dir}')

    for f in csv_files:
        fOutName = f.stem + '_Processed.csv'
        out_f = output_dir / fOutName
        add_columns_to_csv(f, out_f, new_headers, listCreateOrChangeSQLJobsMaintPlans, listCreateOrChangeTriggersSPsTables, listCreateUsersOrChangeAccess, listPerformOrAlterBackupsAndRestores)
        progress = (csv_files.index(f) + 1) / len(csv_files) * 100
        print(f'Progress: {progress:.2f}%')
        

if __name__ == '__main__':
	main()