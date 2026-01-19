<%@include file="/include-internal.jsp"%>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<jsp:useBean id="discoveredRunnersBean" type="jetbrains.buildServer.controllers.admin.projects.DiscoveredRunnersBean" scope="request"/>

<c:set var="objects" value="${discoveredRunnersBean.discoveredObjects}"/>
<c:set var="inProgress" value="${discoveredRunnersBean.discoveryInProgress}"/>
<c:set var="showInProgressOnly" value="${param['inProgressOnly'] == 'true'}"/>
<c:if test="${showInProgressOnly and not inProgress}">
  <c:set var="objects" value="${null}"/>
</c:if>
<form  id="discoveredRunners">
<c:if test="${not empty objects}">
  <table class="parametersTable">
    <tr>
      <th style="text-align: center; width: 1%;">
      </th>
      <th style="width: 20%;">
        Build Step
      </th>
      <th colspan="2">Parameters Description</th>
    </tr>
  <c:forEach items="${objects}" var="objectBean">
    <tr>
      <td style="text-align: center;">
        <forms:checkbox name="runnerId" value="${objectBean.id}"/>
      </td>
      <td><c:out value="${objectBean.displayName}"/></td>
      <td>
        <bs:makeMultiline><bs:makeBreakable text="${objectBean.description}" regex=".{60}"/></bs:makeMultiline>
      </td>
    </tr>
  </c:forEach>
  </table>

  <div style="margin-top: 1em">
  <c:if test="${not empty objects}">
    <forms:button onclick="BS.RunnersDiscovery.addObjects('${buildForm.settingsId}', BS.Util.getSelectedValues($('discoveredRunners'), 'runnerId'));" className="btn_primary">Use selected</forms:button>&nbsp;
  </c:if>
    <forms:button id="updateDiscoveryContainer" onclick="BS.RunnersDiscovery.update('${buildForm.settingsId}');">Refresh</forms:button>
  </div>
</c:if>
</form>

<c:if test="${empty objects and not inProgress and not showInProgressOnly}">
  <c:url value='/admin/editRunType.html?init=1&id=${buildForm.settingsId}&runnerId=${buildForm.buildRunnerBean.id}&runTypeInfoKey=' var="addStepUrl"/>
  <p>No build steps found, <a href="${addStepUrl}">configure build steps manually</a>.</p>
</c:if>
<script type="text/javascript">
  <c:choose>
  <c:when test="${inProgress}">
  BS.RunnersDiscovery.showProgress();
  var updateFunc = function () {
    if (!BS.RunnersDiscovery.showSuggestions('${buildForm.settingsId}')) {
      window.setTimeout(updateFunc, 5000);
    }
  };
  window.setTimeout(updateFunc, 5000);
  </c:when>
  <c:otherwise>
  BS.RunnersDiscovery.hideProgress();
  </c:otherwise>
  </c:choose>
</script>
