/* creating BACKUP files: */
declare @newname nvarchar(255) = '_BU_' + CONVERT(nvarchar(10),getdate(),112) + '_EnrollUser'
EXEC sp_rename 'EnrollUser', @newname; 
GO

declare @newname nvarchar(255) = '_BU_' + CONVERT(nvarchar(10),getdate(),112) + '_UpdateUser'
EXEC sp_rename 'UpdateUser', @newname; 
GO

declare @newname nvarchar(255) = '_BU_' + CONVERT(nvarchar(10),getdate(),112) + '_deleteUser'
EXEC sp_rename 'deleteUser', @newname; 
GO