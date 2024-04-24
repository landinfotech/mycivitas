# Create Windows executable of django project

The purpose of this document is to explain how to create a windows executable from the My Civitas project to be able to be distribution to other machines.

## Enviroment requirements
- Python version 3.9
- Nuitka version 1.3 (link: [Github](https://github.com/Nuitka/Nuitka))
-- PyInstaller is causing to many issues with django
- OSGeo4W

*Please note: nuitka is OS specific. If you want a windows executable, please create package on Windows OS. If you want a Linux ELF executable, create the package on Linux OS*

*Django server is set to run at localhost:8000*

**NB: This document assumes that postgres is installed on target machine and that databases needed have been created/restored**

## Install Build Tools needed for python libraries

1. Download [Visual Studio](https://visualstudio.microsoft.com/visual-cpp-build-tools/) 
![Alt text](./readme%20images/build_tools.png)
2. Run the installer
![Alt text](./readme%20images/c_tools.png)
3. From the install menu tick the box next to "Desktop development with C++"
4. You can add extra packages from the right side menu for C++. Run install


## Set up python virtual enviroment
*Please ensure that python 3.9 is installed on your computer. If a another version of python is installed there is no need to uninstall any other versions. You can choose which version of python to run by adding `-{python version number}` after the python command ex. `python -3.9`. Do not install python from the Microsoft store as this is known to cause issues.*

1. Type the following `python -m venv /path/to/new/virtual/environment` into the terminal
2. To activate the the virtual enviroment type `.\path to virtual env\Scripts\activate` into the terminal
![Alt text](./readme%20images/terminal.png)
**Requirements for django project can be found at `deployment\docker\REQUIREMENTS.txt`**

## Running the django development server
1. Run `pip install -r deployment\docker\REQUIREMENTS.txt`
2. In the file /django_project/core/settings/project.py update the database connection according to your configuration
3. In the terminal run `python manage.py migrate`
4. In the terminal run `python manage.py runserver`

## Possible bugs
1. 

## Installing OSGeo4W
*Please make sure you have internet access*
1. Download [OSGeo4W installer](https://download.osgeo.org/osgeo4w/v2/osgeo4w-setup.exe)
2. Run the installer
![Alt text](./readme%20images/os1.png)
3. Select Express Install, and Next
![Alt text](./readme%20images/os2.png)
4. Pick one or more packages to install, and Next (If you're not sure, select all packages)
5. The selected packages and their required sub packages will be downloaded and installed automatically
6. Navigate to where OSGeo4W has installed, C:\OSGeo4W64\bin or C:\OSGeo4W\bin
7. Locate the file called gdalxxx.dll (xxx refers to version number)
8. Rename gdalxxx.dll to gdal203
9. Copy the entire "OSGeo4W" folder and paste into 'mycivitas/core/settings'

## Install GDAL python library
*If you are having trouble with installing GDAL using pip, please follow below instructions*
1. Download GDAL setup from [this website](https://www.lfd.uci.edu/~gohlke/pythonlibs/#gdal)
Choose the correct version of GDAL for your system (cp refers to the version of python you are using)
2. After you've downloaded GDAL install it with the following command `pip install \path_to_download\`

## Important changes for Windows
1. Copy the contents of `django_project\web-app\static\js\dashboard\community\controller.windows-template.js` and paste into `django_project\web-app\static\js\dashboard\community\controller.js`
- This is to ensure that map panning works correctly on Windows

## Create executable of django_project
1. Cd to the root of the project (in this case the root folder would be mycivitas)
2. Run the following command in the terminal `py -c 'from create_exe_server import *; create_cfx_exe()'` this will create a an exe file. 


## Create dynamic python module
*Dynamic Python modules can be shipped with the exe without the need to install python libraries on target machine*
1. To create a dynamic python module use the following command `py -m nuitka --module {venv\Lib\site-packages\package_name} --include-package={package_name}`
- Breakdown of command:
        1. `{venv\Lib\site-packages\package_name}` is the path to the python library installed in the virtual enviroment
        2. `--include-package={package_name}` is the name of the python library you wish to convert
2. To create a folder with all the needed python modules run `py -c 'from create_exe_server import *; create_modules()'`

## GUI 
**Django server needs a GUI to run, otherwise a browser needs to be opened to access the app. A GUI app has been included with this project (location: mycivitas/gui). The requirements for the GUI app can be found at `mycivitas/gui/requirements.txt`**

### Test GUI
1. After you have created an exe of the django project, include the file location inside of `gui/main.py`. Edit the variable called `path_to_server`. It is recommended that the django exe/standalone dir be placed into the same folder as the gui folder
2. To test the GUI app cd into the 'gui' folder, run `py main.py` (make sure that the django server is running)
![Alt text](./readme%20images/final.png)

### Create exe of GUI
*Below steps are for nuitka. [PyInstaller](https://pyinstaller.org/en/stable/) can be used instead since the GUI is created with pyqt*
**The GUI handles all the logic, including starting the django server**
1. Run `py -m nuitka --follow-imports --output-dir=../mycivitas_exe --plugin-enable=pyqt5 --include-qt-plugins=all main.py` to test if the GUI is behaving as expected. The exe will be exported to a folder called `mycivitas_exe` in the base directory. 
2. To create a standalone directory to distrubute to other machines run `py -m nuitka --output-dir=final_exe --standalone --plugin-enable=pyqt5 --include-qt-plugins=all main.py`. The distrubution directory will be exported to a folder called `final_exe`.
3. To create a single exe file instead of a directory run `py -m nuitka --onefile --output-dir=final_exe --plugin-enable=pyqt5 --include-qt-plugins=all main.py`. The exe will be exported to a folder called `final_exe`. 
4. If you run into an error as 'Module could not be found', add `--include-package=module_name` to the command line
5. Add an icon for the app by adding `--windows-icon-from-ico=your-icon.png` to the command line
6. To change the name of onefile exe, add `--output-filename=FILENAME` to the command line (If you want a standalone directory, rather change main.py to your desired name as `--output-filename=FILENAME` might not work)
7. Paste newly created mycivitas.exe inside of folder where 'manage.exe' is located

## Distribution to other machines
1. The folder called `final_exe` will have all the neccessary files after steps have been followed for the creation of the django exe and the gui exe
2. The folder structure should be as follows:
![Alt text](./readme%20images/structure.png)

## Create Installer
1. Install Inno Setup Compiler 
2. Open 'compile_script_v2.iss' and run compile
3. Installer will be exported into a file called "Output" in same directory as compile script

