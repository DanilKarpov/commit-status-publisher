<%@ include file="/include.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.BasePropertiesBean" scope="request"/>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>

<c:set var="noneMode" value="${propertiesBean.properties['quietPeriodMode'] eq 'DO_NOT_USE'}"/>
<c:set var="defMode" value="${propertiesBean.properties['quietPeriodMode'] eq 'USE_DEFAULT'}"/>
<c:set var="customMode" value="${propertiesBean.properties['quietPeriodMode'] eq 'USE_CUSTOM'}"/>

<tr>
  <td colspan="2">
    <em>VCS Trigger will add a build to the queue when a VCS check-in is detected.</em>
  </td>
</tr>
<tr class="advancedSetting">
  <td colspan="2">
    <c:set var="disabled" value="${not buildForm.template and empty buildForm.snapshotDependenciesBean.dependencies}"/>
    <props:checkboxProperty name="watchChangesInDependencies" disabled="${disabled}" onclick="checkCheckInterval();"/>
    <label for="watchChangesInDependencies" class="rightLabel <c:if test="${disabled == true}">grey</c:if>">Trigger a build on changes in snapshot dependencies<bs:help file="Configuring+VCS+Triggers" anchor="Triggerabuildonchangesinsnapshotdependencies"/></label>
  </td>
</tr>
<l:settingsGroup title="Per-checkin Triggering" className="advancedSetting"/>
<tr class="advancedSetting">
  <td colspan="2">
    <props:checkboxProperty name="perCheckinTriggering" onclick="{
    if (!this.checked) $('groupCheckinsByCommitter').checked = false;
    if (this.checked) $('enableQueueOptimization').checked = false;
    }"/>
    <label for="perCheckinTriggering" class="rightLabel">Trigger a build on each check-in</label>
    <div class="group-checkins-wrapper">
      <props:checkboxProperty name="groupCheckinsByCommitter" onclick="{
      if (this.checked && !$('perCheckinTriggering').checked) {
        $('perCheckinTriggering').checked = true;
        $('enableQueueOptimization').checked = false;
      }
      }"/>
      <label for="groupCheckinsByCommitter" class="rightLabel">Include several check-ins in a build if they are from the same committer</label>
    </div>
  </td>
</tr>
<l:settingsGroup title="Quiet Period Settings" className="advancedSetting"/>
<tr class="advancedSetting">
  <td>
    <label class="rightLabel">Quiet period mode:</label><bs:help file="Configuring+VCS+Triggers" anchor="quietPeriod"/>
  </td>
  <td class="_top">
    <table id="quietPeriodModeTable">
      <tr>
        <td>
          <props:radioButtonProperty name="quietPeriodMode" id="quietPeriod1" value="DO_NOT_USE" onclick="$('quietPeriod').value = ''; $('quietPeriod').disable(); checkCheckInterval(); BS.VisibilityHandlers.updateVisibility('quietPeriodModeTable')"/>
          <label for="quietPeriod1">Do not use</label>
        </td>
      </tr>
      <tr>
        <td>
        <props:radioButtonProperty name="quietPeriodMode" id="quietPeriod2" value="USE_DEFAULT" onclick="$('quietPeriod').value = ''; $('quietPeriod').disable(); checkCheckInterval(); BS.VisibilityHandlers.updateVisibility('quietPeriodModeTable')"/>
        <label for="quietPeriod2">Use default value (${buildForm.defaultQuietPeriod} seconds)</label>
        </td>
      </tr>
      <tr>
        <td>
        <props:radioButtonProperty name="quietPeriodMode" id="quietPeriod3" value="USE_CUSTOM" onclick="$('quietPeriod').enable(); checkCheckInterval(); BS.VisibilityHandlers.updateVisibility('quietPeriodModeTable')"/>
        <label for="quietPeriod3">Custom</label>

        <props:textProperty name="quietPeriod" maxlength="50" size="20" disabled="${not customMode}" onchange="checkCheckInterval()"/><label for="quietPeriod" class="rightLabel">seconds</label>
        <span class="error" id="error_quietPeriod"></span>
        </td>
      </tr>
      <jsp:include page="/admin/triggers/vcsCheckInterval.html"/>
    </table>
    <script type="text/javascript">
      checkCheckInterval();
    </script>
  </td>
</tr>
<l:settingsGroup title="Build Queue Optimization Settings" className="advancedSetting"/>
<tr class="advancedSetting">
  <td colspan="2">
    <props:checkboxProperty name="enableQueueOptimization" onclick="if (this.checked && $('perCheckinTriggering').checked) $('perCheckinTriggering').click();"/>
    <c:set var="queueOptimizationDisabled" value="${propertiesBean.properties['perCheckinTriggering'] and propertiesBean.properties['enableQueueOptimization']}"/>
    <label for="enableQueueOptimization" title="${queueOptimizationDisabled ? 'This setting is not effective because per-checkin triggering is enabled' : ''}"
      ><c:if test="${queueOptimizationDisabled}"
        ><bs:buildStatusIcon type="red-sign" className="warningIcon"
      /></c:if
      > Queued build can be replaced with a more recent build</label>
  </td>
</tr>
<jsp:include page="/admin/triggers/triggerRulesAndBranchFilter.jsp">
  <jsp:param name="defaultBranchFilter" value='+:*'/>
</jsp:include>

