<%@ page import="jetbrains.buildServer.controllers.RunBuildBean" %>
<%@ page import="jetbrains.buildServer.serverSide.BuildTypeOptions" %>
<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ page import="java.time.ZonedDateTime" %>
<%@ page import="java.time.temporal.ChronoUnit" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="runBuildBean" type="jetbrains.buildServer.controllers.RunBuildBean" scope="request"/>
<jsp:useBean id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary" scope="request"/>
<jsp:useBean id="isPersonalPromotion" type="java.lang.Boolean" scope="request"/>
<c:set var="hasSeveralPools" value="${serverSummary.hasSeveralAgentPools}"/>
<c:set value="<%=RunBuildBean.ALL_ENABLED_COMPATIBLE_AGENTS_ID%>" var="allEnabledCompatibleOption"/>
<c:set value="<%=RunBuildBean.POOL_ID_PREFIX%>" var="poolIdPrefix"/>
<c:set value="<%=RunBuildBean.AGENT_TYPE_ID_PREFIX%>" var="agentTypeIdPrefix"/>

<div id="general-tab" class="tabContent">

  <c:if test="${not runBuildBean.buildType.compositeBuildType}">
    <%@ include file="noCompatibleAgentsWarning.jspf" %>
  </c:if>

  <table class="runnerFormTable">
    <c:if test="${not runBuildBean.buildType.compositeBuildType}">
      <tr>
        <th><label for="agentId">Agent: </label></th>
        <td <c:if test="${runBuildBean.hasCustomAgents}">class="modifiedParam"</c:if>>
          <forms:select name="agentId" id="agentId" style="width: 20em" enableFilter="true"
                        onchange="BS.RunBuildDialog.highlightCustomAgent(this);">
            <c:set var="defaultOption" value="the fastest idle agent"/>
            <c:if test="${intprop:getBoolean('teamcity.ui.customBuild.display.run.on.any.agent.option')}">
              <c:set var="defaultOption" value="any compatible agent"/>
            </c:if>
            <forms:option value="">&lt;${defaultOption}&gt;</forms:option>
            <c:set var="agents" value="${runBuildBean.availableAgents}"/>
            <c:set var="groupStarted" value="${false}"/>
            <c:forEach items="${agents}" var="poolAgentsPair">
              <c:if test="${hasSeveralPools}">
                <c:set var="pool" value="${poolAgentsPair.first}"/>
                <c:set var="agentId">${poolIdPrefix}${pool.agentPoolId}</c:set> <!-- to string -->
                <c:set var="poolName"><c:out value="${pool.name}"/></c:set>
                <c:if test="${groupStarted}"></optgroup></c:if>
                <optgroup label="${poolName} Pool">
                <c:set var="groupStarted" value="${true}"/>
                <forms:option value="${agentId}" selected="${runBuildBean.selectedAgentIds[agentId]}">&lt;the fastest idle agent in the ${poolName} pool&gt;</forms:option>
              </c:if>
              <c:forEach items="${poolAgentsPair.second}" var="agentWrapper">
                <c:if test="${agentWrapper.isAgent}">
                  <c:set var="agentId">${agentWrapper.buildAgent.id}</c:set> <!-- to string -->
                  <forms:option value="${agentId}" selected="${runBuildBean.selectedAgentIds[agentId]}"><c:out value="${agentWrapper.buildAgent.name}"/> <bs:agentShortStatus agent="${agentWrapper.buildAgent}" showRunningStatus="${true}" showUnavailable="${true}"/></forms:option>
                </c:if>
              </c:forEach>
              <c:forEach items="${poolAgentsPair.second}" var="agentWrapper">
                <c:if test="${agentWrapper.isAgentType}">
                  <c:set var="agentTypeId">${agentWrapper.agentType.agentTypeId}</c:set> <!-- to string -->
                  <forms:option value="${agentTypeIdPrefix}${agentTypeId}" selected="${runBuildBean.selectedAgentIds[agentTypeId]}">[Cloud] <c:out value="${agentWrapper.agentType.details.name}"/></forms:option>
                </c:if>
              </c:forEach>
            </c:forEach>
            <c:if test="${groupStarted}"></optgroup></c:if>
            <c:if test="${not empty agents}">
              <forms:option value="${allEnabledCompatibleOption}">&lt;All enabled compatible agents&gt;</forms:option>
            </c:if>
          </forms:select>
        </td>
      </tr>
    </c:if>
    <c:set var="buildOptionsHeaderShown" value="false"/>
    <c:set var="personalBuildsAllowed" value="<%=runBuildBean.getBuildType().getOption(BuildTypeOptions.BT_ALLOW_PERSONAL_BUILD_TRIGGERING) && runBuildBean.getPersonalChangeId() == 0%>"/>
    <c:if test="${personalBuildsAllowed}">
      <tr>
        <th class="noBorder"><c:if test="${not buildOptionsHeaderShown}"><c:set var="buildOptionsHeaderShown" value="true"/>Build options:</c:if></th>
        <td class="noBorder">
          <forms:checkbox name="personal" onclick="$j('#personalSettingsRow').toggle();" disabled="${isPersonalPromotion}" checked="${isPersonalPromotion}"/> <label for="personal" >run as a personal build<bs:help file="Personal+Build"/></label>
        </td>
      </tr>

      <c:if test="${afn:permissionGrantedForBuildType(runBuildBean.buildType, 'PATCH_BUILD_SOURCES')}">
      <tr id="personalSettingsRow" style="display: none;">
        <th class="noBorder"></th>
        <td class="noBorder">
          <div style="padding-left: 1.5em; margin-top: -0.3em">
            <div class="personalPatch">
              <c:if test="${intprop:getBooleanOrTrue('teamcity.ui.customBuild.personalPatchUpload.enabled')}">
                <c:set var="uploadMsg">Click to upload or drag & drop a patch in unified diff format</c:set>
                <div id="patchDropZone">
                  <span id="patchDropZoneTitle">${uploadMsg}</span>
                  <span id="resetPatch" onclick="document.getElementById('file:personalPatch').value = ''; $j('#patchDropZoneTitle').text('${uploadMsg}'); $j(this).hide(); return false;">x</span>
                </div>
                <forms:file name="personalPatch" attributes="form='personalPatchUploadForm'" onchange="{
                   var path = $j(this).val();
                   var parts = path.replace(/\\\\/g, '/').split('/');
                   var title = BS.trimText(parts[parts.length - 1], 40);
                   var fileInput = document.getElementById('file:personalPatch');
                   title += ' (' + Math.round(fileInput.files[0].size/1024) + ' KB)';
                   $j('#patchDropZoneTitle').text(title);
                   $j('#resetPatch').show();
                }"/>
                <div class="smallNote">If uploaded, the patch will be applied on the agent before the build and reverted afterwards<bs:help file="Personal+Build#Direct+Patch+Upload"/></div>
                <input type="hidden" name="uploadPatch" value="true" form="personalPatchUploadForm"/>
                <input type="hidden" name="buildTypeId" value="${runBuildBean.buildType.externalId}" form="personalPatchUploadForm"/>
                <input type="hidden" name="stateKey" value="<c:out value="${param['stateKey']}"/>" form="personalPatchUploadForm"/>
                <input type="hidden" name="tc-csrf-token" value="${sessionScope['tc-csrf-token']}" form="personalPatchUploadForm"/>
              </c:if>
            </div>

            <!-- include PlaceId.RUN_CUSTOM_PERSONAL_BUILD_FRAGMENT -->
            <ext:includeExtensions placeId="<%=PlaceId.RUN_CUSTOM_PERSONAL_BUILD_FRAGMENT %>"/>
            <!-- end of include PlaceId.RUN_CUSTOM_PERSONAL_BUILD_FRAGMENT -->

          </div>
        </td>
      </tr>
      </c:if> <!-- has PATCH_BUILD_SOURCES -->

    </c:if>
    <authz:authorize allPermissions="REORDER_BUILD_QUEUE">
      <tr>
        <th class="noBorder"><c:if test="${not buildOptionsHeaderShown}"><c:set var="buildOptionsHeaderShown" value="true"/>Build options:</c:if></th>
        <td class="noBorder">
          <forms:checkbox name="moveToTop"/> <label for="moveToTop">put the build to the queue top</label>
        </td>
      </tr>
    </authz:authorize>
    <c:choose>
      <c:when test="${not runBuildBean.buildType.compositeBuildType}">
        <tr>
          <th class="noBorder"><c:if test="${not buildOptionsHeaderShown}"><c:set var="buildOptionsHeaderShown" value="true"/>Build options:</c:if></th>
          <td class="noBorder">
            <forms:checkbox name="cleanSources" checked="${runBuildBean.cleanSourcesEnabled}"/> <label for="cleanSources" >delete all files in the checkout directory before the build</label>
          </td>
        </tr>
        <c:if test="${runBuildBean.dependencies.hasSnapshotDependencies}">
          <tr>
            <th class="noBorder"></th>
            <td class="noBorder">
              <div style="padding-left: 1.5em; margin-top: -0.3em">
                <forms:checkbox name="applyCleanSourcesToDependencies" /> <label for="applyCleanSourcesToDependencies" >apply to all snapshot dependencies</label>
              </div>
            </td>
          </tr>
        </c:if>
      </c:when>
      <c:when test="${runBuildBean.dependencies.hasSnapshotDependencies}">
        <tr>
          <th class="noBorder"><c:if test="${not buildOptionsHeaderShown}"><c:set var="buildOptionsHeaderShown" value="true"/>Build options:</c:if></th>
          <td class="noBorder">
            <forms:checkbox name="cleanSources" onclick="$('applyCleanSourcesToDependencies').value = this.checked; if (this.checked) { $('rebuildDependenciesMode').selectedIndex = 1; $('rebuildDependenciesMode').onchange(); }"/> <label for="cleanSources" >delete all files in checkout directory before each snapshot dependency build</label>
            <input type="hidden" id="applyCleanSourcesToDependencies" name="applyCleanSourcesToDependencies" value="false"/>
          </td>
        </tr>
      </c:when>
    </c:choose>

    <tr>
      <th class="noBorder">Date & Time:</th>
      <td class="noBorder">
        <div id="runScheduleContainer"></div>
          <script>
            (() => ReactUI.renderScheduleBuild('runScheduleContainer', {}))();
          </script>
        </div>
      </td>
    </tr>

  </table>
</div>
<script type="text/javascript">
  var patchDropZone = document.getElementById('patchDropZone');
  if (patchDropZone) {
    var patchDropZoneTitle = document.getElementById('patchDropZoneTitle');
    var fileInput = document.getElementById('file:personalPatch');
    patchDropZone.ondragover = patchDropZone.ondragenter = function(e) {
      patchDropZone.style.backgroundColor = 'whitesmoke';
      e.preventDefault();
    };

    patchDropZone.ondrop = function(e) {
      fileInput.files = e.dataTransfer.files;
      fileInput.onchange(e);
      patchDropZone.style.backgroundColor = '';
      e.preventDefault();
    };

    patchDropZoneTitle.onclick = function(e) {
      $j('#resetPatch').click();
      fileInput.click();
    }
  }
</script>
