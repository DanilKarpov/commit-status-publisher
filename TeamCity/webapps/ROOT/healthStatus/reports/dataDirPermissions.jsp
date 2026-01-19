<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
The following principals have write access to the TeamCity data directory (<c:out value="${healthStatusItem.additionalData['dataDirectory']}"/>):
<ul>
  <c:forEach items="${healthStatusItem.additionalData['suspiciousPrincipals']}" var="principal">
    <li><c:out value="${principal}"/></li>
  </c:forEach>
</ul>

For security reasons, write access should be allowed only to TeamCity user account and Administrators.

