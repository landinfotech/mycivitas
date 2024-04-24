import subprocess
import os

modules_list = "--include-package=django --include-package=web-app --include-plugin-directory=django_project/amlit --include-plugin-directory=django_project/amlit_helpdesk --include-plugin-directory=django_project/civitas --include-plugin-directory=django_project/core --include-plugin-directory=django_project/web-app --include-package=rest_framework --include-package=pinax --include-package=celery --include-package=djstripe --include-package=rest_framework_gis --include-package=helpdesk --include-package=account --include-package=geopy --include-package=nominatim --include-package=translations --include-package=bootstrap4form --include-package=sass_processor "

package_list = [
    "werkzeug",
    "stripe",
    "django.utils.translation",
    "psycopg2",
    "translations",
    "django_extensions",
    "encodings",
    "inspect",
    "django",
    "gettext",
    "rest_framework", 
    "pinax", 
    "celery", 
    "djstripe", 
    "rest_framework_gis", 
    "helpdesk", 
    "account", 
    "geopy", 
    "nominatim", 
    "bootstrap4form", 
    "sass_processor",
    "text_unidecode",
]

directory_list = [
    "django_project/amlit",
    "django_project/amlit_helpdesk", 
    "django_project/civitas", 
    "django_project/core", 
    "django_project/web-app", 
    # "django_project/OSGeo4W", 
]

cx_list = [
    "dotenv",
    "werkzeug",
    "stripe",
    "amlit",
    "amlit_helpdesk", 
    "civitas", 
    "core", 
    "web-app", 
    "django.templatetags.i18n",
    "django.template.loader_tags",
    "django.utils.translation",
    "psycopg2",
    "translations",
    "django",
    "django_extensions",
    "encodings",
    "inspect",
    "gettext",
    "rest_framework", 
    "celery", 
    "rest_framework_gis", 
    "helpdesk", 
    "account", 
    "geopy", 
    "nominatim", 
    "bootstrap4form", 
    "sass_processor",
    "pinax",
    "text_unidecode",
    "djstripe"
]

def package_to_str(list):
    final_str = ""
    for val in list:
        new_val = f"--include-package={val}"
        final_str = " ".join([final_str, new_val])
    return final_str

def directory_to_str(list):
    final_str = ""
    for val in list:
        new_val = f"--include-plugin-directory={val}"
        final_str = " ".join([final_str, new_val])
    return final_str

def package_to_str_cfx(list):
    final_str = "--packages="
    for val in list:
        new_val = f"{val}"
        final_str = ",".join([final_str, new_val])
    fixed = ''.join(final_str.split(',', 1))
    return fixed

def django_module_to_str_cfx(list):
    final_str = "--include-files="
    for val in list:
        new_val = f"{val}"
        final_str = ",".join([final_str, new_val])
    fixed = ''.join(final_str.split(',', 1))
    return fixed


def module_name_to_str_cfx(list):
    final_str = "--includes="
    for val in list:
        new_val = f"{val}"
        final_str = ",".join([final_str, new_val])
    fixed = ''.join(final_str.split(',', 1))
    return fixed


def create_django_exe():
    if not os.path.exists("final_exe"):
        os.mkdir("final_exe")
    package_str = package_to_str(package_list)
    directory_str = directory_to_str(directory_list)
    os.system(f"py -m nuitka --follow-imports {package_str} {directory_str} --output-dir=final_exe .\django_project\manage.py")

def create_standalone():
    if not os.path.exists("final_exe"):
        os.mkdir("final_exe")
    package_str = package_to_str(package_list)
    directory_str = directory_to_str(directory_list)
    os.system(f"py -m nuitka --standalone --clang  --execute-with-pythonpath --run {package_str} {directory_str} --output-dir=final_exe .\django_project\manage.py")

def create_onefile():
    if not os.path.exists("final_exe"):
        os.mkdir("final_exe")
    package_str = package_to_str(package_list)
    directory_str = directory_to_str(directory_list)
    os.system(f"py -m nuitka --onefile --follow-stdlib  {package_str} {directory_str} --output-dir=final_exe .\django_project\manage.py")

def create_modules():
    if not os.path.exists("final_exe\exported_modules"):
        os.mkdir("final_exe\exported_modules")
    for module in package_list:
        os.system(f"py -m nuitka --module .venv\Lib\site-packages\{module} --output-dir=final_exe\exported_modules --include-package={module}")

def create_cfx_exe():
    if not os.path.exists("final_exe"):
        os.mkdir("final_exe")
    dir_str = django_module_to_str_cfx(directory_list)
    module_str = package_to_str_cfx(package_list)
    module_names = module_name_to_str_cfx(cx_list)
    packages_names = package_to_str_cfx(cx_list)
    # print(dir_str)
    # os.system(f"cxfreeze -c {dir_str} {module_str} {module_names} {packages_names} --base-name Win32GUI  .\django_project\manage.py --target-dir mycivitas_exe")
    os.system(f"cxfreeze -c  {dir_str} {module_str} {module_names} {packages_names}  .\django_project\manage.py --target-dir mycivitas_golden_albatros_110")
