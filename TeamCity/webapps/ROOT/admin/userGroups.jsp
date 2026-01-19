<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="profile" tagdir="/WEB-INF/tags/userProfile" %>
<jsp:useBean id="adminEditUserForm" type="jetbrains.buildServer.controllers.admin.users.AdminEditUserForm" scope="request"/>

<profile:userGroups user="${adminEditUserForm.editee}" canAddToGroups="${adminEditUserForm.canAddToAnyGroup}" profileForm="${adminEditUserForm}"/>
