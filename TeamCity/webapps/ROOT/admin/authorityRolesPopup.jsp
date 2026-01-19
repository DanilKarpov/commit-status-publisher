<%@ page import="jetbrains.buildServer.controllers.profile.AuthorityRolesBean" %>
<%@ page import="jetbrains.buildServer.serverSide.auth.RolesHolder" %>
<%@include file="/include-internal.jsp"%>
<%@ taglib prefix="roles" tagdir="/WEB-INF/tags/roles"%>
<jsp:useBean id="rolesBean" type="jetbrains.buildServer.controllers.profile.AuthorityRolesBean" scope="request"/>
<jsp:useBean id="rolesHolder" type="jetbrains.buildServer.serverSide.auth.RolesHolder" scope="request"/>
<c:set var="rolesCount" value='${fn:length(rolesHolder.roles)}'/>
<c:set var="inheritedRolesCount" value='<%=AuthorityRolesBean.getNumberOfInheritedRoles(rolesHolder)%>'/>
<c:set var="totalRolesCount" value='${rolesCount + inheritedRolesCount}'/>
<div class="authorityRolesPopup">
<div>
  <c:if test="${totalRolesCount == 0}">There are no roles assigned.</c:if>
  <c:if test="${totalRolesCount > 0}">
    <c:if test="${rolesCount > 0}">There <bs:are_is val="${rolesCount}"/> <strong>${rolesCount}</strong> role<bs:s val="${rolesCount}"/> assigned directly.</c:if>
    <c:if test="${inheritedRolesCount > 0}"><strong>${inheritedRolesCount}</strong> role<bs:s val="${inheritedRolesCount}"/> <bs:are_is val="${inheritedRolesCount}"/> inherited from the groups.</c:if>
  </c:if>
</div>
<c:if test="${not empty rolesBean.roles}">
<roles:rolesTable rolesList="${rolesBean.roles}" editable="${false}" modifiableRolesAvailable="${false}" showTableCaption="${false}"/>
</c:if>

<c:set var="inheritedRolesMap" value="${rolesBean.inheritedRoles}"/>
<c:if test="${not empty inheritedRolesMap}">
<c:set var="groups" value="<%=rolesBean.getInheritedRoles().keySet()%>"/>
<c:forEach items="${groups}" var="group">
  <div class="groupHeader">Roles inherited from the group <bs:editGroupLink group="${userGroupMapper.getUserGroupDto(group)}"><strong><c:out value="${group.name}"/></strong></bs:editGroupLink> <c:if test="${not empty group.description}">(<c:out value="${group.description}"/>)</c:if></div>
  <roles:rolesTable rolesList="${inheritedRolesMap[group]}" editable="${false}" modifiableRolesAvailable="${false}" showTableCaption="${false}"/>
</c:forEach>
</c:if>
</div>