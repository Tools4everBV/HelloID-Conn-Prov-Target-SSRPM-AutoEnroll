# HelloID-Conn-Prov-Target-SSRPM-AutoEnroll

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |

<br />

## Introduction
The interface to communicate directly with the SSRPM database. For this connector you need to execute create-storedProcedures.sql on your SSRPM Database.
Please note this requires the SSRPM profile options to see "Storage of User Answers" to "Clear Text"

## Prerequisites
- [ ] HelloID Provisioning agent (cloud or on-prem).
- [ ] Stored procedures in you Database
- [ ] Connection variables (server, database optional login)
- [ ] HelloID service-account has read/write permissions on SSRPM-DB


# HelloID Docs
The official HelloID documentation can be found at: https://docs.helloid.com/


