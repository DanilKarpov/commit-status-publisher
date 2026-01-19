<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="params" type="jetbrains.buildServer.controllers.RunBuildParameters" scope="request"/>

<%--@elvariable id="runBuildBean" type="jetbrains.buildServer.BuildInstanceData"--%>

<authz:authorize projectId="${runBuildBean.buildType.projectId}" allPermissions="CUSTOMIZE_BUILD_PARAMETERS">
  <jsp:attribute name="ifAccessDenied">
    <c:set var="readOnly" value="${true}"/>
  </jsp:attribute>
</authz:authorize>

<div id="properties-tab" style="display: none;" class="tabContent">
  <table class="runnerFormTable wideLabel buildParameters">
    <tbody style="${readOnly || params.customRunDialogForRunButton ? 'display:none' : ''}">
    <c:if test="${params.allowAddingBuildParameters}">
    <tr class="newParameterRow">
      <td colspan="2" class="noBorder">
        <select id="customBuild-paramType" name="paramType">
          <option value="conf">Configuration parameter</option>
          <option value="system" class="systemPropOption">System property</option>
          <option value="env">Environment variable</option>
        </select>
      </td>
      <td><a href="#" onclick="BS.RunBuildDialog.resetAllParameters(); return false;">Reset all</a></td>
    </tr>
    </c:if>
    <tr class="addParam">
      <td class="paramName noBorder">
        <forms:textField name="customBuild-parameterName" value="" style="width: 100%;"/>
      </td>
      <td class="paramValue noBorder">
        <div class="completionIconWrapper">
          <forms:textField name="customBuild-parameterValue" value="" noAutoComplete="true" className="buildTypeParams" expandable="true"/>
        </div>
      </td>
      <td class="edit noBorder">
        <input type="button" class="btn btn_mini" value="add" onclick="BS.RunBuildDialog.addParameter()"/>
      </td>
    </tr>
    </tbody>
    <c:if test="${params.customRunDialogForRunButton}">
      <tr>
        <td colspan="3">
          The parameters below are marked as necessary for review.
          <c:if test="${readOnly}"><p>
            You don't have sufficient permissions to modify build parameters.
          </p></c:if>
        </td>
      </tr>
    </c:if>
    <c:forEach var="group" items="${params.parameterGroups}">
      <bs:changeRequest key="group" value="${group}">
        <jsp:include page="runCustomBuildParametersContent.jsp"/>
      </bs:changeRequest>
    </c:forEach>
  </table>
</div>


<div id="newParamTemplate"><!--
  <tr class="modifiedParam">
      <td class="paramName"><forms:textField name="[prefix]name" value="" style="width: 100%" defaultText="<Name>"/></td>
      <td class="paramValue"><div class="completionIconWrapper"><textarea rows="1" cols="30" style="margin:0; padding:0; resize: vertical; width: 100%;" class="one_line buildTypeParams" name="[prefix]value" id="[prefix]value[id]" wrap="soft" autocomplete="off"></textarea></div></td>
      <td class="edit"><a href="#" onclick="BS.RunBuildDialog.removeParameter(this.parentNode.parentNode); return false">Delete</a></td>
  </tr>
  --></div>

  <script type="text/javascript">
    <c:if test="${params.containsRequiredParameters}">
    BS.Util.show('customRunPropertiesRequired');
    </c:if>
    <c:if test="${readOnly}">
    Form.disable("customConfigParams");
    Form.disable("customBuildSystemProps");
    Form.disable("customBuildEnvVars");
    </c:if>
  </script>
