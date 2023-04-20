# CDRApi
Call Detail Record Business Intelligence Platform API

## Technology and Choices
For the technologies, Mojoulicious framework and MySQL database were chosen, along with modules such as Mojo::Upload, Mojo::IOLoop, Mojo::Promise, Mojo::IOLoop::Subprocess, and DBIx::Class. Although not completely familiar with all the technologies, an attempt was made to select technologies as close as possible to those currently in use.

# Assumptions
It was assumed that in the future, microservices will not be utilized, and the future functionality of the API will differ from the existing one, preventing the controller from becoming overcrowded with code. Additionally, it is assumed that file upload handling will change in the future.

## Database
The MySQL database is assumed to have the following structure:
        caller_id BIGINT not null,
        recipient BIGINT not null,
        call_date DATE,
        end_time TIME,
        duration INT,
        cost DECIMAL(10, 3),
        reference VARCHAR(255) not null,
        currency VARCHAR(3),
        type ENUM('1', '2'),
        PRIMARY KEY (reference)
`caller_id` and `recipient` are bigints, which could be varchar as well. However, bigint was chosen for an extra layer of protection against inserting letters. `call_date` has the format yyyy-mm-dd (different from the CSV), and `cost` has a maximum of 10 digits with 3 decimal places. The `type` field only has two possible values (1 and 2), and the primary key is the `reference` field.

## File Upload and Load
It is assumed that the user can identify bad rows in the file or that this will be a future enhancement. When uploading and loading the file, only a success message and a number of bad rows are displayed, without logging them in a separate file.

## Controllers
The controllers are divided into two: one for data uploading and loading, and another for cdr/stats retrieval. Although it could be managed with one controller for this API, future considerations for changing the upload and load process led to the decision to split them.

## Asynchronous?
It is assumed that there will not be a high volume of concurrent requests and the queries are relatively simple, so asynchronous subroutines were not used, except for upload/load.

# How to Run the App?
You'll need Mojoulicious and sqlserver installed on the computer;

First we need to create the database : 

        CREATE DATABASE cdr;
        USE cdr;

Crete the table;

        CREATE TABLE call_records (
            caller_id BIGINT not null,
            recipient BIGINT not null,
            call_date DATE,
            end_time TIME,
            duration INT,
            cost DECIMAL(10, 3),
            reference VARCHAR(255) not null,
            currency VARCHAR(3),
            type ENUM('1', '2'),
            PRIMARY KEY (reference)
        );

We need to create a db schema. Open dbschema.conf in the root folder and change the user and password if needed. After that run dbicdump dbschema.conf
it dumps the database structure unde the Schema folder. Open CDRApi/lib/CDRApi/Model/DB.pm change the username and password if needed and the use lib with your path to the lib directory;

Modify the paths also in the test file CDRApi/t/basic.t and config file CDRApi/c_d_r_api.yml

If the configuration is correct and the sql server is running you should be able to run the app.
                ~/Documents/CDRApi$ morbo  -l http://localhost:3001 script/cdrapi  
You can choose any port you want.  

Execute
                curl 'http://127.0.0.1:3001/cdrs/reference/a'
and you should expect and '[]' response

Execute
                prove -v t/basic.t 


## See `CDRapi_Documentation.doc` for Usage Documentation

# Considerations/Future Enhancements
1. Code simplicity: the current code is simple and straightforward. However, if the application is expected to grow, consider splitting the code or creating additional classes.
        Create a separate class for handling database interactions (now handled directly in the controller UPDATE: created a model to handle data)
        Create a separate class for input validation (input validation is basic in this app, we recieve an error if the input is not valid subroutine also in the controller)
        Split the controller into smaller controllers
All of this was taken into account, but the size of the app made me keep it as simple and small as possible.
2. File upload: consider third-party hosting services, SFTP, or providing a streaming mechanism to allow for multipart file upload.
3. Endpoint modifications: may be required depending on future requirements.
4. Validation: improvements may be needed in the future.
