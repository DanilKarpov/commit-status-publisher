<%@ page import="jetbrains.buildServer.controllers.parameters.serverHealth.DuplicateInheritedRemoteParameterHealthReport" %>
<%@ page import="jetbrains.buildServer.controllers.parameters.serverHealth.DuplicateInheritedRemoteParameterHealthReport" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<c:set var="duplicateParameters" value='<%=healthStatusItem.getAdditionalData().get(DuplicateInheritedRemoteParameterHealthReport.PARAMETERS)%>'/>


  <c:if test="${not empty duplicateParameters}">
    The following parameters conflict with matching inherited remote parameteters:
    <ul>
      <c:forEach items="${duplicateParameters}" var="duplicate">
        <li>${duplicate.parameter.name} defined in ${duplicate.identifier}</li>
      </c:forEach>
    </ul>

    <br/>

    These inherited parameters were modified but will continue using settings of their source parameters.
    To avoid unexpected behavior, create stand-alone parameters with unique names and required settings, or click Reset to discard the custom settings.
  </c:if>
