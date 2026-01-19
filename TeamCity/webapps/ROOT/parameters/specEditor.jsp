<%@ page import="jetbrains.buildServer.controllers.parameters.ParameterContext" %>
<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props"  %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="pctx" uri="/WEB-INF/functions/parameters-context" %>
<jsp:useBean id="types" scope="request" type="java.util.Collection<jetbrains.buildServer.controllers.parameters.ParameterTypeInfo>"/>
<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterEditContext"/>
<jsp:useBean id="displayMode" scope="request" type="jetbrains.buildServer.serverSide.parameters.ControlDisplayMode"/>
<jsp:useBean id="includeExtensions" scope="request" type="java.lang.Boolean"/>

<jsp:useBean id="cns" class="jetbrains.buildServer.controllers.parameters.ParameterConstants"/>
<jsp:useBean id="propertiesBean" scope="request" type="jetbrains.buildServer.controllers.BasePropertiesBean"/>
<c:set var="projectIdBuildTypeIdQuery" value="${pctx:getProjectAndBuildTypeQueryFromContext(context)}" />

<table class="runnerFormTable">
  <tr>
    <th><label for="${cns.editTypeLabelParameterName}">Label:</label></th>
    <td>
      <props:textProperty name="${cns.editTypeLabelParameterName}" className="longField"/>
      <span class="smallNote">Custom label to be shown in custom run build dialog instead of parameter name</span>
    </td>
  </tr>
  <tr>
    <th><label for="${cns.editTypeDescriptionParameterName}">Description:</label></th>
    <td>
      <props:textProperty name="${cns.editTypeDescriptionParameterName}" className="longField" expandable="true"/>
      <span class="smallNote">Description to be shown in custom run build dialog</span>
    </td>
  </tr>
  <tr>
    <th><label for="${cns.editTypeDisplayParameterName}">Display:</label></th>
    <td>
      <props:selectProperty name="${cns.editTypeDisplayParameterName}" className="longField">
        <c:forEach var="it" items="${cns.editTypeDisplayParameterValues}">
          <props:option value="${it.value}" selected="${it.value eq displayMode.value}"><c:out value="${it.description}"/></props:option>
        </c:forEach>
      </props:selectProperty>
      <span class="smallNote">Use 'Hidden' to hide parameter from custom run dialog. Use 'Prompt' to force custom run dialog with the parameter displayed on every build start.</span>
    </td>
  </tr>

  <tr>
    <th><label for="readOnly">Read-only:</label></th>
    <td>
      <props:checkboxProperty name="readOnly" checked="false"/>
      <span class="smallNote">Make the parameter impossible to override with another value</span>
      <span id="error_readOnly" class="error"></span>
    </td>
  </tr>

  <tr>
    <th><label for="specParameterTypeChooser">Type:<l:star/></label></th>
    <td>
      <c:set var="selectedType" value="${context.description.parameterType}"/>
      <forms:select id="specParameterTypeChooser" name="${cns.editTypeParameterName}" className="longField">
        <forms:option value="" selected="${fn:length(selectedType) eq 0}">-- Choose control type --</forms:option>
        <c:forEach var="it" items="${types}">
          <jsp:useBean id="it" type="jetbrains.buildServer.controllers.parameters.ParameterTypeInfo"/>
          <forms:option value="${it.type}" selected="${it.type eq selectedType}"><c:out value="${it.description}"/></forms:option>
        </c:forEach>
        <c:if test="${ (not includeExtensions) and ( fn:length(selectedType) ne 0 )}">
          <c:set var="selectedType"><c:out value="${selectedType}"/></c:set>
          <forms:option value="${selectedType}" selected="${true}">Unknown type: <c:out value="${selectedType}"/></forms:option>
        </c:if>
      </forms:select>
    </td>
  </tr>
</table>

<c:url var="parametersEditFormUrl" value="${cns.editTypeParameterUrl}${projectIdBuildTypeIdQuery}"/>
<bs:refreshable containerId="specParameterEditorContainer" pageUrl="${parametersEditFormUrl}">
  <table class="runnerFormTable">
    <c:choose>
      <c:when test="${includeExtensions}">
        <bs:changeRequest key="${cns.renderContext}" value="${context}">
          <jsp:include page="${cns.editSpecControllerPath}" />
        </bs:changeRequest>

    </c:when>
    <c:otherwise>
      <!-- no edit -->
    </c:otherwise>
    </c:choose>
  </table>
  <div>
    <span id="error_unknownTypeSpec" class="error" style="margin-left: 0;"/>
    <span id="error_incorrectSpec" class="error" style="margin-left: 0;"/>
  </div>
</bs:refreshable>
