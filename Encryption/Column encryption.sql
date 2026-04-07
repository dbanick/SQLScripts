--stage keys and certificate

use [database]
go
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SomeStrongPassword';
GO
CREATE CERTIFICATE cert_name  
   WITH SUBJECT = 'PII content / Social Security Numbers';  
GO  
CREATE SYMMETRIC KEY sym_key_name  
    WITH ALGORITHM = AES_256  
    ENCRYPTION BY CERTIFICATE cert_name;  
GO  


--to encrypt
OPEN SYMMETRIC KEY sym_key_name DECRYPTION BY CERTIFICATE cert_name
update tablename SET columnname = ENCRYPTBYKEY(KEY_GUID('sym_key_name'),CONVERT(varbinary(128), columnname))
go

--to decrypt
OPEN SYMMETRIC KEY sym_key_name DECRYPTION BY CERTIFICATE cert_name
select ID, columnname, CONVERT(nvarchar,DECRYPTBYKEY(columnname)) as decrypted from tablename

--permissions
GRANT CONTROL ON CERTIFICATE::[cert_name] TO [Domain\User]
GRANT VIEW DEFINITION ON SYMMETRIC KEY::[sym_key_name] TO [Domain\User] 