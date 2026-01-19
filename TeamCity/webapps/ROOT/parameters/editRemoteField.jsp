<%@ page import="jetbrains.buildServer.controllers.parameters.ParameterContext" %>
<%@include file="/include-internal.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="pctx" uri="/WEB-INF/functions/parameters-context" %>
<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterEditContext"/>
<jsp:useBean id="cns" class="jetbrains.buildServer.serverSide.parameters.remote.RemoteParameterConstants"/>
<jsp:useBean id="remoteParameters" scope="request" type="java.util.Collection<jetbrains.buildServer.controllers.parameters.remote.RemoteParameterControlProvider>"/>
<jsp:useBean id="parametersConstants" class="jetbrains.buildServer.controllers.parameters.ParameterConstants"/>
<jsp:useBean id="newDialog" scope="request" type="java.lang.Boolean"/>
<c:set var="readOnly" scope="request" value="${param.readOnly}"/>
<c:set var="inherited" scope="request" value="${param.inherited}"/>


<c:set var="projectIdBuildTypeIdQuery" value="${pctx:getProjectAndBuildTypeQueryFromContext(context)}" />

<tr class="${newDialog ? 'addBorder' : ''}">
  <th style="${newDialog ? '': 'width: 20.8%'}"><label for="prop:${cns.remoteTypeParam}">Connection Type: <l:star/></label></th>
  <td>
    <c:set var="selectedRemoteType" value="${context.description.parameterTypeArguments[cns.remoteTypeParam]}"/>
    <forms:select id="specRemoteParameterTypeChooser" name="prop:${cns.remoteTypeParam}" className="longField">
      <forms:option value="" selected="${fn:length(selectedRemoteType) eq 0}">-- Choose Connection Type --</forms:option>
      <c:forEach var="it" items="${remoteParameters}">
        <forms:option value="${it.remoteParameterType}" selected="${it.remoteParameterType eq selectedRemoteType}"><c:out
            value="${it.remoteParameterDescription}"/></forms:option>
      </c:forEach>
    </forms:select>
  </td>
</tr>

<table class="runnerFormTable remoteParameter">
  <c:url var="parametersEditFormUrl" value="${parametersConstants.editTypeParameterUrl}${projectIdBuildTypeIdQuery}&newDialog=${newDialog}&readOnly=${readOnly}&inherited=${inherited}"/>

  <bs:refreshable containerId="remoteSpecParameterEditorContainer" pageUrl="${parametersEditFormUrl}">

    <bs:changeRequest key="${parametersConstants.renderContext}" value="${context}">
      <jsp:include page="${parametersConstants.editRemoteSpecControllerPath}"/>
      <script type="text/javascript">
        {
          const readOnly = "<bs:forJs>${readOnly}</bs:forJs>".toLowerCase() === "true";
          const inherited = "<bs:forJs>${inherited}</bs:forJs>".toLowerCase() === "true";
          if (inherited && !readOnly){
            BS.EditParameterDialog.disableForInheritance();
          } else {
            BS.EditParameterDialog.setReadOnlyState(readOnly);
          }
        }
      </script>
    </bs:changeRequest>
    <div>
      <span id="error_unknownRemoteTypeSpec" class="error" style="margin-left: 0;"/>
      <span id="error_incorrectRemoteSpec" class="error" style="margin-left: 0;"/>
    </div>
  </bs:refreshable>
</table>

<script type="application/javascript" defer>
  {
    const remoteParameterChooser = $('specRemoteParameterTypeChooser');
    remoteParameterChooser.onchange = () => updateVisibility();

    function updateVisibility() {
      const params = "${cns.remoteTypeParam}=" + (remoteParameterChooser.value == "" ? "--not_selected--" : remoteParameterChooser.value);
      $('remoteSpecParameterEditorContainer').refresh(null, params);
    }

    updateVisibility();
  }
</script>

