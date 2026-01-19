<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<jsp:useBean id="_object" scope="request" type="jetbrains.buildServer.serverSide.TeamCityNode"/>
<jsp:useBean id="_objectId" scope="request" type="java.lang.String"/>
<c:choose>
  <c:when test="${not empty _object}">
    <c:out value="\"${_object.id}\""/>
  </c:when>
  <c:otherwise>
    <c:out value="\"${_objectId}\""/>
  </c:otherwise>
</c:choose>