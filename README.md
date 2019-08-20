
# Creating a basic S2I builder image  

Originally forked from https://hub.docker.com/r/mpiech/s2i-clojure/

## Getting started  

### Usage Dependencies

#### Building
- This image uses openjdk-8 and install clojure 1.10.1 and the latest stable release of leiningen.
  - lein is installed in `${HOME}` so to access it you have to do `${HOME}/lein`
  in the environment variable
- Each project that uses must define environment variables in an .s2i/environment file.
  - The format for these is key-value ie. FOO=bar
  - The variables required are:
    - `UBERJAR=<command to create uberjar>`
    - `ARTIFACT_PATH=<path to uberjar>`
    - `RUN_JAR=<command to run uberjar>`
- The JAR generated must end with `standalone.jar`
- For specifying the run command, the uberjar will be moved to the home directory and the jar will be named `app-standalone.jar`
  - ie. `java -jar ${HOME}/app-standalone.jar` was the original execution for this image. The RUN_JAR variable should use the same conventions.

#### Installing Artifact Only
 - Another option is to just install an artifact into the image.
 - The variables required are:
   - `INSTALL_ARTIFACT=true`
   - `ARTIFACT_PATH=<path to uberjar>`
   - `RUN_JAR=<command to run uberjar>`

#### Example

- If using lein to build uberjar use these values in `.s2i/environment`
  - `UBERJAR=${HOME}/lein ring uberjar`
  - `ARTIFACT_PATH=/opt/app-root/src/src/target/uberjar/*standalone.jar`
  - `RUN_JAR=java -jar ${HOME}/app-standalone.jar`
- If using deps uberjar (https://github.com/tonsky/uberdeps/)
  - `UBERJAR=clj -A:uberjar --target target/app-standalone.jar`
  - `ARTIFACT_PATH=target/app-standalone.jar`
  - `RUN_JAR= java -cp ${HOME}/app-standalone.jar clojure.main -m <main-namespace name>`
- If using artifact only deploy (Main difference is lack of UBERJAR environment value)
  - `INSTALL_ARTIFACT=true`
  - `ARTIFACT_PATH=target/app-standalone.jar`
  - `RUN_JAR= java -cp ${HOME}/app-standalone.jar clojure.main -m <main-namespace name>`

#### Troubleshooting
  - Do not use ${HOME} in ARTIFACT_PATH. It is not set up to expand that out.

### Files and Directories  
| File                   | Required? | Description                                                  |
|------------------------|-----------|--------------------------------------------------------------|
| Dockerfile             | Yes       | Defines the base builder image                               |
| s2i/bin/assemble       | Yes       | Script that builds the application                           |
| s2i/bin/usage          | No        | Script that prints the usage of the builder                  |
| s2i/bin/run            | Yes       | Script that runs the application                             |
| s2i/bin/save-artifacts | No        | Script for incremental builds that saves the built artifacts |
| test/run               | No        | Test script for the builder image                            |
| test/test-app          | Yes       | Test application source code                                 |

#### Dockerfile
Create a *Dockerfile* that installs all of the necessary tools and libraries that are needed to build and run our application.  This file will also handle copying the s2i scripts into the created image.

#### S2I scripts

##### assemble
Create an *assemble* script that will build our application, e.g.:
- build python modules
- bundle install ruby gems
- setup application specific configuration

The script can also specify a way to restore any saved artifacts from the previous image.   

##### run
Create a *run* script that will start the application.

##### save-artifacts (optional)
Create a *save-artifacts* script which allows a new build to reuse content from a previous version of the application image.

##### usage (optional)
Create a *usage* script that will print out instructions on how to use the image.

##### Make the scripts executable
Make sure that all of the scripts are executable by running *chmod +x s2i/bin/**

#### Create the builder image
The following command will create a builder image named s2i-clojure based on the Dockerfile that was created previously.
```
docker build -t s2i-clojure .
```
The builder image can also be created by using the *make* command since a *Makefile* is included.

Once the image has finished building, the command *s2i usage s2i-clojure* will print out the help info that was defined in the *usage* script.

#### Testing the builder image
The builder image can be tested using the following commands:
```
docker build -t s2i-clojure-candidate .
IMAGE_NAME=s2i-clojure-candidate test/run
```
The builder image can also be tested by using the *make test* command since a *Makefile* is included.

#### Creating the application image
The application image combines the builder image with your applications source code, which is served using whatever application is installed via the *Dockerfile*, compiled using the *assemble* script, and run using the *run* script.
The following command will create the application image:
```
s2i build test/test-app s2i-clojure s2i-clojure-app
---> Building and installing application from source...
```
Using the logic defined in the *assemble* script, s2i will now create an application image using the builder image as a base and including the source code from the test/test-app directory.

#### Running the application image
Running the application image is as simple as invoking the docker run command:
```
docker run -d -p 8080:8080 s2i-clojure-app
```
The application, which consists of a simple static web page, should now be accessible at  [http://localhost:8080](http://localhost:8080).

#### Using the saved artifacts script
Rebuilding the application using the saved artifacts can be accomplished using the following command:
```
s2i build --incremental=true test/test-app nginx-centos7 nginx-app
---> Restoring build artifacts...
---> Building and installing application from source...
```
This will run the *save-artifacts* script which includes the custom code to backup the currently running application source, rebuild the application image, and then re-deploy the previously saved source using the *assemble* script.
