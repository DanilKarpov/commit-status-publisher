<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="parentGroups" type="java.util.Collection" scope="request"/>
<c:set var="name">
  <c:choose>
    <c:when test="${not empty user}"><strong><c:out value="${user.descriptiveName}"/></strong></c:when>
    <c:when test="${not empty group}"><strong><c:out value="${group.name}"/></strong></c:when>
  </c:choose>
</c:set>
<div>
<c:if test="${fn:length(parentGroups) == 0}">${name} is not included into any group.</c:if>
<c:if test="${fn:length(parentGroups) > 0}">${name} is included into <strong>${fn:length(parentGroups)}</strong> group<bs:s val="${fn:length(parentGroups)}"/>.</c:if>
</div>

<c:if test="${fn:length(parentGroups) > 0}">
  <ul class="availableGroupsList">
    <c:forEach items="${parentGroups}" var="group">
      <li><c:out value="${group.name}"/><c:if test="${not empty group.description}"> (<c:out value="${group.description}"/>)</c:if></li>
    </c:forEach>
  </ul>
</c:if>
 