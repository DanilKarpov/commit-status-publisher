<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="unusedProperties" value="${healthStatusItem.additionalData['unusedProperties']}"/>
<c:set var="defaultUsedProperties" value="${healthStatusItem.additionalData['defaultUsedProperties']}"/>
<c:set var="message">
  <br>
  <c:if test="${unusedProperties != null}">
    <p>
      <b>Some <a href="<c:url value="/admin/admin.html?item=diagnostics&tab=properties"/>">internal properties</a> are not used by the server at the moment and may be obsolete.
        Consider reviewing and cleaning them:</b>
      <br>
      <c:forEach items="${unusedProperties}" var="unusedProperty">
        <c:out value="${unusedProperty}"/><br>
      </c:forEach>
    </p>
  </c:if>
  <c:if test="${defaultUsedProperties != null}">
    <p>
      <b>Some <a href="<c:url value="/admin/admin.html?item=diagnostics&tab=properties"/>">internal properties</a> have the same values as default.
        Consider reviewing and cleaning the redundant properties:</b>
      <br>
      <c:forEach items="${defaultUsedProperties}" var="defaultUsedProperty">
        <c:set var="property" value="${defaultUsedProperty.key}"/>
        <c:set var="value" value="${defaultUsedProperty.value}"/>
        <c:out value="${property}"/>=<c:out value="${value}"/><br>
      </c:forEach>
    </p>
  </c:if>
</c:set>
<c:out value="${message}" escapeXml="false"/>