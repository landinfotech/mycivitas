# User Manual Django Administration Site

This site is the administration site for the MyCivitas platform, and only specific superusers can access it.

![admin option](./img/admin-1.png)

## Important Tables to Manage

There are a variety of tables to manage on the Django Admin site but the two key ones are the [Users Table](#users-table) and the [Organisation Table](#organisation-table).

### Users Table

The Django admin user table is a central component within the Django admin interface, providing a comprehensive view of user-related data for the application. This table serves as a management hub for user accounts, offering essential information about each user in a tabular format.

![User Table](./img/admin-2.png)

1. **User:** Click on the `Users` to view the users table.

    ![User Table](./img/admin-3.png)

    1. **Search Functionality:** The User Table provides a powerful search functionality allowing the administrators to search user records based on various criteria. To perform a search, locate the search bar at the top left corner of the User Table.
    The administrators can search by:
        - Email Address
        - First Name
        - Last Name
    
    Simply enter the relevant information into the search bar and hit enter to display matching records.

    2. **Action Dropdown:** Administrators can perform batch actions on selected user records using the `Action Dropdown`. To select multiple records, use the checkbox in front of each user record. Once selected, open the Action Dropdown and choose the desired action, e.g., Delete selected users. Confirm the action and the selected records will be processed accordingly. This feature streamlines bulk user management tasks, enhancing efficiency for administrators.

    3. **User Name:** Clicking on the username of a user opens a detailed view of that user's record. A new page will open, providing comprehensive information about the selected user.

        ![User Record](./img/admin-4.png)

        1. **Username:** The administrator can see the user's email address here.

        2. **Change Password Form** The administrator can click on `this form` link, to change the user password. When the administrator clicks on this link opens the change password page.

            ![Change Password](./img/admin-5.png)

            1. **Password:** The administrators required to provide the new password here.
            
            2. **Password (again):** The administrators are required to re-enter the new password for confirmation. This field ensures accuracy and helps prevent input errors.

            3. **Change Password Button:** After entering the new password and confirmation, users can click the `CHANGE PASSWORD` button to submit the form. Upon successful submission, the system will update the user's password, enhancing the security of their account.
        
        3. **Personal Information Section:** The Personal Info section of the User Table contains essential information about each user, facilitating easy identification and management.

            - **First Name:** Displays the first name of the user. Administrators can view and edit this field to update user details.

            - **Last Name:** Displays the last name of the user. Administrators can view and edit this field to update user details.

            - **Title:** Displays the user's title, such as `Mr.`, providing a formal address. Administrators can view and edit this field to update user details.

            - **Phone and Ext:** Displays the user's phone number along with an extension field side by side. Administrators can view and edit these fields to update user contact details.

            - **Avatar:** Displays the user's profile picture or avatar. Administrators can view and edit this field to update the user's profile image.

        4. **Permission Section:** The `Permission Section` allows administrators to assign specific permissions to users, tailoring their access and roles within the application.

            - **Active:** Checkbox indicating whether the user account is active or inactive. Administrators can toggle this checkbox to control user account status.

            - **Staff Status:** Checkbox granting staff status to the user. Staff status provides additional privileges within the application. Administrators can manage staff status by checking or unchecking the checkbox.

            - **Superuser Status:** Checkbox granting superuser status to the user. Superusers have elevated privileges, often including full control over the application. Administrators can assign or remove superuser status by checking or unchecking the checkbox.
        
        5. **History Button:** The History button allows administrators to access the history log of the user, providing insights into changes and activities related to the user account.

        ![Group and Permission](./img/admin-6.png)

        6. **Group (+):** Administrators can create user groups by clicking on the plus icon. Upon clicking the plus icon, a popup window will open, allowing administrators to define the group's details. In the popup, administrators can specify:

            ![Group](./img/admin-7.png)

            - **Group Name:** A unique identifier for the group.
            - **Permissions:** Assign specific permissions to the group, determining the access levels for members.
            
            After providing the necessary information, administrators can save the group.
        
        7. **Permissions:** Available permissions for the group. Administrators can choose permissions from the list and assign them to the user.

        8. **Arrow:** Using these arrows, administrators can add or remove the permissions to the user.

        9. **Choose All:** The button to choose all of the permissions and assign them to the user.

        10. **Remove All:** The button to choose all of the permissions and remove them from the user.

        ![dates](./img/admin-8.png)

        11. **Last Login Date:** The administrators can view or update the last login date of the user.
        
        12. **Date Joined:** The administrators can view or update the joining date of the user.

        13. **Save:** Save the current record and then get redirected to the Django Admin Table/record list.
        
        14. **Save and add another:** Save the current record and then be redirected to a new page to add a new record.

        15. **Save and continue editing:** Save the current record while still showing the current record.

        16. **Delete button:** Delete the currently opened record. It will take administrators to a confirmation page.

    4. **Adding a New User:** The administrators can create a new user by clicking on the `add user` button, when the administrators click on this button a new page opens for adding the user record.

        ![Add User](./img/admin-10.png)

        1. **Email Address:** Administrators should enter a unique email address for the new user.

        2. **Password:** Administrators should create a strong password for the user.

        3. **Confirm Password:** Re-enter the same password in the confirmation field to verify accuracy.

        4. **Save:** Save the current record and then get redirected to the Django Admin Table/record list.

            ![user-created](./img/admin-11.png)

        5. **Save and add another:** Save the current record and then be redirected to a new page to add a new record.

        6. **Save and continue editing:** Save the current record while still showing the current record.

    5. **Filters:** The administrators can filter the user table using the available filters on the right side of the tables. 

        ![filtered tables](./img/admin-12.png)
