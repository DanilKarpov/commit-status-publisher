<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<%--@elvariable id="updatesLink" type="java.lang.String"--%>

<c:choose>
  <c:when test="${not empty updatesLink}">
    Important <a href="<c:url value='${updatesLink}'/>">security updates</a> are available for this TeamCity version.
  </c:when>
  <c:otherwise>
    Important security updates are available for this TeamCity version. Please contact your system administrator.
  </c:otherwise>
</c:choose>
