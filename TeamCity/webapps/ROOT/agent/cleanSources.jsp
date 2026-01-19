<%@ include file="/include-internal.jsp" %>
<div>
  <bs:messages key="sourcesCleanedMessage"/>
  <a href="#" onclick="BS.AgentResetSources.showResetSourcesDialog(); return false">Clean sources on this agent</a><bs:help file="Clean+Checkout"/>
</div>
<c:url value='/ajax.html' var="actionUrl"/>
<bs:modalDialog formId="resetSources"
                title="Choose build configurations"
                action="${actionUrl}"
                closeCommand="BS.AgentResetSources.close()"
                saveCommand="BS.AgentResetSources.submitResetSources()">

  <forms:saving id="cleanSourcesProgress" className="progressRingInline"/>

  <bs:refreshable containerId="cleanSourcesDialogContent" pageUrl="${pageUrl}">
    <c:if test="${param['showCleanSourcesDialog'] != null}">
      <jsp:useBean id="agentDetails" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailsForm"/>
      <c:set var="configsForCleanSources" value="${agentDetails.configurationsForCleanSources}"/>

      <c:choose>
        <c:when test="${fn:length(configsForCleanSources) == 0}">
          <div>There are no build configurations on this agent to enforce clean checkout for.</div>
        </c:when>
        <c:otherwise>
          <div>Choose build configurations to enforce clean checkout for:</div>

          <select multiple hidden name="buildTypeId" id="resetSourcesBuildTypeId">
            <c:if test="${afn:permissionGrantedGlobally('CLEAN_AGENT_SOURCES')}">
              <option value="">&lt;All build configurations&gt;</option>
            </c:if>
            <c:forEach items="${configsForCleanSources}" var="buildType">
              <c:if test="${afn:permissionGrantedForBuildType(buildType, 'CLEAN_BUILD_CONFIGURATION_SOURCES') or afn:permissionGrantedGlobally('CLEAN_AGENT_SOURCES')}">
                <option class="inplaceFiltered" value="${buildType.externalId}"><c:out value="${buildType.fullName}"/></option>
              </c:if>
            </c:forEach>
          </select>
          <div id="resetSourcesBuildTypeIdSelect"></div>
          <script>
            {
              const select = document.getElementById('resetSourcesBuildTypeId');
              const options = [...select.options];
              ReactUI.renderConnected(document.getElementById('resetSourcesBuildTypeIdSelect'), ReactUI.ProjectBuildTypeSelect, {
                multiselect: true,
                expandAll: true,
                includeRoot: options.some(option => option.value === ''),
                includedBuildTypes: options.map(option => option.value).filter(value => value !== ''),
                onCheck(items) {
                  select.value = null;
                  items.forEach(item => {
                    options.find(option => option.value === item.id).selected = true;
                  })
                }
              });
            }
          </script>

          <input type="hidden" name="resetSources" value="${agentDetails.agent.id}"/>

          <div class="popupSaveButtonsBlock">
            <forms:submit label="Clean sources" id="resetSourcesSubmitButton"/>
            <forms:cancel onclick="BS.AgentResetSources.close()"/>
            <forms:saving id="resetSourcesProgress"/>
          </div>
        </c:otherwise>
      </c:choose>
    </c:if>
  </bs:refreshable>

</bs:modalDialog>
