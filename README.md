# HelloID-Conn-Prov-Target-SSRPM-AutoEnroll

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-SSRPM-AutoEnroll](#helloid-conn-prov-target-connectorname)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Provisioning PowerShell V2 connector](#provisioning-powershell-v2-connector)
      - [Correlation configuration](#correlation-configuration)
      - [Field mapping](#field-mapping)
    - [Connection settings](#connection-settings)
    - [Prerequisites](#prerequisites)
    - [Remarks](#remarks)
  - [Setup the connector](#setup-the-connector)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-SSRPM-AutoEnroll_ is a _target_ connector.

It allows for the automated enrollment of Active Directory users in ssrpm.

Please note this connector requires the SSRPM profile options to see "Storage of User Answers" to "Clear Text". Therefore it may not be applicable to most SSRPM implementations, as this is not a recommended configuration in SSRPM.

 _SSRPM-AutoEnroll_ communicates directly with the SSRPM databae. For this connector you need to execute create-storedProcedures.sql on your SSRPM Database.

The following lifecycle actions are available:

| Action                                  | Description                               |
| --------------------------------------- | ----------------------------------------- |
| create.ps1                              | Enrolls an Active Directory user into SSRPM |
| delete.ps1                              | Removes an user from the enrolled users
| update.ps1                              | Updates properties of an enrolled user      |


## Getting started

### Provisioning PowerShell V2 connector

#### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _SSRPM-AutoEnroll_ to a person in _HelloID_.

Correlation is based on the sAMAccountName.
It requires the MicrosoftActiveDirectory connector to the user domain to be set to use account info

To properly setup the correlation:

1. Open the `Correlation` tab.

2. Specify the following configuration:

    | Setting                   | Value                             |
    | ------------------------- | --------------------------------- |
    | Enable correlation        | `True`                            |
    | Person correlation field  | `Accounts.MicrosoftActiveDirectory.sAMAccountName |
    | Account correlation field | `SAMAccountName`                  |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

#### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

### Connection settings

The following settings are required to connect to the API.

| Setting  | Description                        | Mandatory |
| -------- | ---------------------------------- | --------- |
| ConnectionString | The complete sql connection string to connect to the database  | Yes  |

### Prerequisites
- [ ] HelloID Provisioning agent (cloud or on-prem).
- [ ] Stored procedures in you Database
- [ ] Connection variables (server, database optional login)
- [ ] HelloID service-account has read/write permissions on SSRPM-DB

### Remarks

 - For this connector you need to execute create-storedProcedures.sql on your SSRPM Database.
 Make sure to modify the name of the database in this script to the name of your database.
 - The ProfileID in the field configuration must be (one-time) manually looked up in the SSRPM database
 - Note that the ProfileId specified here overrules the ProfileId configured for the user/group in ssrpm


## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
