# CDRApi
Call Detail Record Business Intelligence Platform API



# Technology and choises
For the technologies I choose Mojoulicious framework and mysql database with modules like  Mojo::Upload Mojo::IOLoop Mojo::Promise Mojo::IOLoop::Subprocess DBIx::Class. I was not so familiar with all the technologies but I tried to make the api technologies as close as possible as the ones that you use.

# Assumptions
I assumed that in the future we will not use microservices, and the future functionality of the api will be diffrent from the one existing so the controller will not get too crowded with code. Also the upload is handled differently in the future.
# Database
I assumed that the database has the following structure, and is a mysql database. 
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

caller_id and recipient are bigints, we could do a varchar too. But i choose bigint because we have a extra layer of protection in order not to insert letters
call date has the format yyyy-mm-dd (different from the csv)
cost is a max 10 digits with 3 floats.
type only has 2 possible values 1 and 2 
the primary key is the reference

# File upload and load
I assumed that the user has a method of finding the bad rows in the file, or will be a future enhancement. For this reason when we upload the file and load it(more about the file loading in the consideratios/future enhancements) we only have a message of success and a number for the bad rows without putting them in a log file.

# Controllers
I split the controllers into 2 one for data uploading and loading and one for cdr/stats retrieving. For this api it could be done in 1 controller without beeing unmanagable. but a future consideration to change the upload and load made me split them;

# Asynchronous?
 I assumed that for i would not have a high volume of concurrent requests and the queries are rather simple so i didnt use async subturines only for upload/load 


# How to run the app?
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

You can insert a value to see that everything is working properly 

        INSERT INTO call_records (caller_id, recipient, call_date,end_time, duration, cost, reference,currency,type)
        VALUES ('442036000000','44800833833',STR_TO_DATE("16/08/2016", "%d/%m/%Y"),'14:00:47','244','0','C50B5A7BDB8D68B8512BB14A9D363CAA1','GBP','2'); 

We need to create a db schema. Open dbschema.conf in the root folder and change the user and password if needed. After that run dbicdump dbschema.conf
it dumps the database structure unde the Schema folder. Open CDRApi/lib/CDRApi/Model/DB.pm change the username and password if needed and the use lib with your path to the lib directory;

Modify the paths also in the test file CDRApi/t/basic.t and config file CDRApi/c_d_r_api.yml

If the configuration is correct and the sql server is running you should be able to run the app.
    ~/Documents/CDRApi$ morbo  -l http://localhost:3001 script/cdrapi  
You can choose any port you want.  

You can do a 
    curl 'http://127.0.0.1:3001/cdrs/reference/a'
and you should expect and '[]' response

run 
    prove -v t/basic.t 
from the CDRApi directory
You should pass al the tests and now the app is running and has been tested 
# see Documentation.doc for usage documentation

# considerations/future enhancements
1. In its current form, the code is relatively simple and straightforward. However, if you expect the application to grow and incorporate more features, it might be beneficial to split the code or create additional classes. 
    -Create a separate class for handling database interactions (now handled directly in the controller UPDATE: created a model to handle data)
    -Create a separate class for input validation (input validation is basic in this app, we recieve an error if the input is not valid subroutine also in the controller)
    -Split the controller into smaller controllers
All of this was taken into account, but the size of the app made me keep it as simple and small as possible.
Also we should have in mind if we want to adapt the api to support microservices. If that was the case then the app will be for example split in 3 pieces:
    cdr_by_reference
    call_statistics
    caller_id_and_expensive_calls
for each microservice.

2. API versioning. For this app size api versioning was not implemented but taken into consideration.
3. File upload. In the current api the file is uplaoded directly and full size, but we can consider third party hosting services (ex amazon s3), sftp or using the client to split the files into smaller parts and then upload them individually. 
4. the endpoints could suffer modifications depending on the future requirements.
5. The validation could be improved in the future.