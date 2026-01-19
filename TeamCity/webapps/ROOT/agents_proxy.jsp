<%@ include file="include-internal.jsp"%>
<%--@elvariable id="reactUI" type="java.lang.Boolean"--%>
<%--@elvariable id="tab" type="java.lang.String"--%>
<%--@elvariable id="reactTab" type="java.lang.String"--%>
<jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"/>
<c:choose>
  <c:when test="${reactUI}">
    <jsp:include page="${reactTab}"/>
  </c:when>
  <c:otherwise>
    <jsp:include page="${tab}"/>
  </c:otherwise>
</c:choose>