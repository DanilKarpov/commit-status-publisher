<%@include file="/include-internal.jsp"%>
<jsp:useBean id="userGroup" type="jetbrains.buildServer.groups.UserGroup" scope="request"/>
<jsp:useBean id="userList" type="java.util.List" scope="request"/>
<c:set var="usersCount" value="${fn:length(userGroup.directUsers)}"/>
<div>
  <c:if test="${usersCount == 0}">There are no users.</c:if>
  <c:if test="${usersCount == 1}"><strong>1</strong> user included into the group.</c:if>
  <c:if test="${usersCount > 1}"><strong>${usersCount}</strong> users included into the group.</c:if>
  <c:if test="${usersCount > fn:length(userList)}"><br/>Showing no more than <strong>${fn:length(userList)}</strong> users.</c:if>
</div>

<table class="settings groupUsersTable">
  <c:forEach items="${userList}" var="user" varStatus="pos">
    <tr>
      <td>
        <bs:editUserLink user="${user}"><bs:avatar user="${user}"/><c:out value="${user.descriptiveName}"/></bs:editUserLink>
        <c:if test="${afn:permissionGrantedGlobally('VIEW_USER_PROFILE') or afn:permissionGrantedGlobally('CHANGE_USER')}">
          <c:if test="${fn:length(user.email) > 0}">(<c:out value="${user.email}"/>)</c:if>
        </c:if>
      </td>
    </tr>
  </c:forEach>
</table>
