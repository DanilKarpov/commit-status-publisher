<%@ page import="jetbrains.buildServer.controllers.parameters.ParameterContext" %>
<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props"  %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="pctx" uri="/WEB-INF/functions/parameters-context" %>
<jsp:useBean id="types" scope="request" type="java.util.Collection<jetbrains.buildServer.controllers.parameters.ParameterTypeInfo>"/>
<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterEditContext"/>
<jsp:useBean id="isValueRequired" scope="request" type="java.lang.Boolean"/>
<jsp:useBean id="displayMode" scope="request" type="jetbrains.buildServer.serverSide.parameters.ControlDisplayMode"/>
<jsp:useBean id="includeExtensions" scope="request" type="java.lang.Boolean"/>
<c:set var="readOnly" scope="request" value="${param.readOnly}"/>
<c:set var="inherited" scope="request" value="${param.inherited}"/>

<jsp:useBean id="cns" class="jetbrains.buildServer.controllers.parameters.ParameterConstants"/>
<jsp:useBean id="propertiesBean" scope="request" type="jetbrains.buildServer.controllers.BasePropertiesBean"/>
<c:set var="projectIdBuildTypeIdQuery" value="${pctx:getProjectAndBuildTypeQueryFromContext(context)}" />

<bs:linkCSS>
  /css/specEditor.css
</bs:linkCSS>

<table class="runnerFormTable newSpecTable userDefinedParametersTable">
  <tr>
    <th><label class="editParameterLabel" for="specParameterTypeChooser">Value type:<l:star/></label></th>
    <td>
      <c:set var="selectedType" value="${context.description.parameterType}"/>
      <forms:select id="specParameterTypeChooser" name="${cns.editTypeParameterName}" className="longField">
        <forms:option value="" selected="${fn:length(selectedType) eq 0}">-- Choose control type --</forms:option>
        <c:forEach var="it" items="${types}">
          <forms:option value="${it.type}" selected="${it.type eq selectedType}"><c:out value="${it.description}"/></forms:option>
        </c:forEach>
        <c:if test="${ (not includeExtensions) and ( fn:length(selectedType) ne 0 )}">
          <c:set var="selectedType"><c:out value="${selectedType}"/></c:set>
          <forms:option value="${selectedType}" selected="${true}">Unknown type: <c:out value="${selectedType}"/></forms:option>
        </c:if>
      </forms:select>
    </td>
  </tr>
  <tr id="parameterValueRow">
    <th>
      <label class="editParameterLabel" for="parameterValue">Value:</label>
    </th>
    <td>
      <div class="completionIconWrapper parameterWrapper">
        <forms:textField expandable="true" name="parameterValue" style="width: 100%;" className="buildTypeParams" maxheight="1000"/>
      </div>
      <span class="error" id="error_parameterValue"></span>
      <span class="smallNote">Type '%' for reference completion</span>
    </td>
  </tr>
  <input type="hidden" id="readOnly" name="readOnly" value="<bs:escapeForJs forHTMLAttribute='true' text='${readOnly}'/>"/>
</table>

<c:url var="parametersEditFormUrl" value="${cns.editTypeParameterUrl}${projectIdBuildTypeIdQuery}&readOnly=${readOnly}&inherited=${inherited}"/>
<bs:refreshable containerId="specParameterEditorContainer" pageUrl="${parametersEditFormUrl}">
  <table class="runnerFormTable newSpecTable">
    <c:choose>
      <c:when test="${includeExtensions}">
        <bs:changeRequest key="${cns.renderContext}" value="${context}">
          <script type="text/javascript">
            {
              const isValueRequired = ${isValueRequired};
              const parameterValueRow = $("parameterValueRow");
              if (isValueRequired){
                parameterValueRow.show();
              } else {
                parameterValueRow.hide();
              }

              const readOnly = "<bs:forJs>${readOnly}</bs:forJs>".toLowerCase() === "true";
              const inherited = "<bs:forJs>${inherited}</bs:forJs>".toLowerCase() === "true";
              if (inherited && !readOnly){
                BS.EditParameterDialog.disableForInheritance();
              } else {
                BS.EditParameterDialog.setReadOnlyState(readOnly);
              }
            }
          </script>
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

<table class="runnerFormTable newSpecTable">
  <tr id="appearanceSettingsRow">
    <th>
      <label class="editParameterLabel">Appearance settings:</label>
    </th>
    <td>
      <div>
        <a class="btn appearanceSettingsBtn" href="#" role="button" showdiscardchangesmessage="false" onclick="BS.EditParametersSpecDialog.showCustomDialogSettings(event)">
          <span class="icon_before icon16 addNew">
            Customize settings for the "Run custom build" dialog
          </span>
        </a>
      </div>
    </td>
  </tr>
  <tr id="runCustomBuildSettingsRow" class="customBuildSettings" style="display: none">
    <th>&ldquo;Run custom build&rdquo; dialog settings</th>
    <td id="resetAppearanceSettingsText">
      <div>
        <a class="btn smallNote appearanceSettingsBtn" href="#" role="button" showdiscardchangesmessage="false" onclick="BS.EditParametersSpecDialog.resetCustomDialogSettings(event)">
          Delete appearance settings
        </a>
      </div>
    </td>
  </tr>
</table>

<table class="runnerFormTable newSpecTable">
  <tr class="customBuildSettings" style="display: none;">
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
  <tr class="customBuildSettings" style="display: none;">
    <th><label for="${cns.editTypeDescriptionParameterName}">Description:</label></th>
    <td>
      <props:textProperty name="${cns.editTypeDescriptionParameterName}" className="longField" expandable="true"/>
      <span class="smallNote">Description to be shown in custom run build dialog</span>
    </td>
  </tr>
  <tr class="customBuildSettings" style="display: none;">
    <th><label for="${cns.editTypeLabelParameterName}">Label:</label></th>
    <td>
      <props:textProperty name="${cns.editTypeLabelParameterName}" className="longField"/>
      <span class="smallNote">Custom label to be shown in custom run build dialog instead of parameter name</span>
    </td>
  </tr>
  <tr class="customBuildSettings" style="display: none;">
    <th><label for="readOnly">Read-only:</label></th>
    <td>
      <props:checkboxProperty name="readOnly" checked="false"/>
      <span class="smallNote">Make the parameter impossible to override with another value</span>
      <span id="error_readOnly" class="error"></span>
    </td>
  </tr>
</table>