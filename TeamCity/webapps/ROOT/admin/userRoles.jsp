<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="profile" tagdir="/WEB-INF/tags/userProfile" %>
<%@ taglib prefix="roles" tagdir="/WEB-INF/tags/roles" %>
<jsp:useBean id="adminEditUserForm" type="jetbrains.buildServer.controllers.admin.users.AdminEditUserForm" scope="request"/>

<roles:authorityRoles authorityRolesBean="${adminEditUserForm.userRolesBean}" 
                   editable="${adminEditUserForm.canEditPermissions}"
                   availableRolesBean="${adminEditUserForm.availableRolesBean}"
                   rolesHolderId="${adminEditUserForm.editee.id}"/>

