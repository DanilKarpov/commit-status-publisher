<%@ taglib prefix="roles" tagdir="/WEB-INF/tags/roles" %>
<jsp:useBean id="editGroupBean" type="jetbrains.buildServer.controllers.admin.groups.EditGroupBean" scope="request"/>

<roles:authorityRoles authorityRolesBean="${editGroupBean.rolesBean}"
                   editable="true"
                   availableRolesBean="${editGroupBean.availableRolesBean}"
                   rolesHolderId="group:${editGroupBean.group.key}"/>
