<%@ page import="jetbrains.buildServer.controllers.profile.AuthorityRolesBean" %><%@
    page import="jetbrains.buildServer.serverSide.auth.RolesHolder" %><%@
    page import="jetbrains.buildServer.web.util.WebUtil" %><%@
    include file="/include-internal.jsp" %><%@
    taglib prefix="admin" tagdir="/WEB-INF/tags/admin"

%><jsp:useBean id="userListForm" type="jetbrains.buildServer.controllers.admin.users.UserListForm" scope="request"
/><jsp:useBean id="availableRolesBean" type="jetbrains.buildServer.controllers.user.AvailableRolesBean" scope="request"
/><jsp:useBean id="pageUrl" type="java.lang.String" scope="request"
/><c:set var="currentTab" value="users"
/><c:set var="userListPager" value="${userListForm.pager}" scope="request"
/><c:set var="encodedCameFromTitle" value='<%=WebUtil.encode("Users")%>'
/><c:set var="encodedCameFromUrl" value="<%=WebUtil.encode(pageUrl)%>"
/><c:set var="usersCount" value="${userListForm.numOfRegisteredUsers}" scope="request"
/><c:set var="userProfileAccessible" value="${afn:permissionGrantedGlobally('VIEW_USER_PROFILE') or afn:permissionGrantedGlobally('CHANGE_USER_NOTIFICATIONS') or afn:permissionGrantedGlobally('ASSIGN_USERS_ADD_SUBGROUPS') or afn:permissionGrantedForAnyProject('CHANGE_USER_ROLES_IN_PROJECT')}" scope="request"/>

<c:set var="canAddToGroups" value="${afn:permissionGrantedGlobally('CHANGE_USER') or afn:permissionGrantedForAnyProject('ASSIGN_USERS_ADD_SUBGROUPS')}"/>
<c:set var="canDeleteUsers" value="${afn:permissionGrantedGlobally('DELETE_USER')}"/>
<c:set var="canChangeRoles" value="${serverSummary.perProjectPermissionsEnabled and
                      (afn:permissionGrantedGlobally('CHANGE_USER') or afn:permissionGrantedForAnyProject('CHANGE_USER_ROLES_IN_PROJECT'))}"/>

<div>
  <div id="userList">
    <bs:messages key="userCreated" />
    <bs:messages key="userAccountRemoved" />

    <jsp:include page="usersList.jsp"/>

    <admin:assignRolesDialog availableRolesBean="${availableRolesBean}"/>
    <admin:unassignRolesDialog availableRolesBean="${availableRolesBean}"/>
  </div>
</div>

<jsp:include page="/admin/attachToGroups.html"/>

<forms:modified id="users-actions-docked">
  <jsp:body>
    <div class="bulk-operations-toolbar fixedWidth">
      <span class="users-operations">
        <c:if test="${canAddToGroups}">
          <a href="#" class="btn btn_primary submitButton" onclick="return BS.UserListForm.addSelected();">Add to groups</a>
        </c:if>
        <c:if test="${canChangeRoles}">
          <a href="#" class="btn btn_primary submitButton" onclick="return BS.UserListForm.toggleSelected(true);">Assign roles</a>
          <a href="#" class="btn btn_primary submitButton" onclick="return BS.UserListForm.toggleSelected(false);">Unassign roles</a>
        </c:if>
        <c:if test="${canDeleteUsers}">
          <a href="#" class="btn btn_primary submitButton" onclick="return BS.UserListForm.removeSelected();">Remove users</a>
        </c:if>
      </span>
    </div>
  </jsp:body>
</forms:modified>
