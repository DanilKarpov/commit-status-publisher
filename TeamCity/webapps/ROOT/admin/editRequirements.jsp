<%@ page import="jetbrains.buildServer.controllers.buildType.ParameterInfo" %>
<%@ page import="jetbrains.buildServer.requirements.GeneralRequirements" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<c:set var="requirementsBean" value="${buildForm.requirementsBean}"/>
<c:url var="genralSettingsAutocompletionUrl" value="/agentParametersAutocompletion.html"/>
<c:set var="generalRequirementsEnabledProperty" value="teamcity.general.agent.requirements.update.ui.enabled"/>
<admin:editBuildTypePage selectedStep="requirements">
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/compatibilityList.css
      /css/admin/requirements.css
    </bs:linkCSS>

    <script type="text/javascript">
      $j(document).ready(function() {
        <c:if test="${intprop:getBoolean(generalRequirementsEnabledProperty)}">
          <c:if test="${buildForm.readOnly}">
            BS.GeneralRequirementsForm.setReadOnly();
          </c:if>
        </c:if>
      });
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <c:if test="${intprop:getBoolean(generalRequirementsEnabledProperty)}">
      <div class="section noMargin">
        <h2 class="noBorder">General requirements</h2>
        <bs:smallNote>This section allows to configure some of the most common requirements</bs:smallNote>
        <c:set var="unlimitedResourceString" value="<%=GeneralRequirements.UNLIMITED_RESOURCE_STRING%>"/>
        <form action="<c:url value='/admin/editRequirements.html?id=${buildForm.settingsId}'/>"
              onsubmit="return BS.GeneralRequirementsForm.updateGeneralRequirements()" id="editGeneralRequirementsForm">
          <table class="runnerFormTable">
            <tr>
              <th><label>Operating systems:</label></th>
              <td>
                <c:set var="myOperatingSystems" value="${requirementsBean.operatingSystems}"/>
                <div id="operatingSystemsOptions">
                  <c:forEach var="os" items="${requirementsBean.supportedOperationSystems}">
                    <forms:checkbox name="operatingSystems" id="os_${os}" value="${os}" checked="${myOperatingSystems.contains(os)}"/>
                    <label for="os_${os}">${os}</label>
                    <br>
                  </c:forEach>
                </div>

                <c:if test="${empty myOperatingSystems}">
                  <bs:smallNote>Operating system requirements are not specified (any will be used)</bs:smallNote>
                </c:if>
              </td>
            </tr>
            <c:if test="${intprop:getBoolean('teamcity.general.agent.cpu.requirements.update.ui.enabled')}">
              <c:set var="cpuCountParameter" value="<%=GeneralRequirements.CPU_PARAMETER_NAME%>"/>
              <tr>
                <th rowspan="2"><label>CPU count:</label></th>
                <td>
                  <label for="minCpuCount" class="fixedLabel">from: </label>
                  <c:set var="minCpuCountValue" value="${requirementsBean.minCpuCount}"/>

                  <c:set var="defaultCpuCount" value="0"/>
                  <input type="text" name="minCpuCount" value="${minCpuCountValue}" maxlength="1024" id="maxCpuCount"
                         onfocus="if (this.value == '${defaultCpuCount}') this.value = '';"
                         onfocusout="if (this.value.empty()) this.value = '${defaultCpuCount}'"
                         style="width: 12rem"
                  />
                </td>
              </tr>
              <tr>
                <td>
                  <label for="maxCpuCount" class="fixedLabel">to:</label>
                  <c:set var="maxCpuCountValue" value="${requirementsBean.maxCpuCount}"/>
                  <c:set var="unlimitedCpuCount" value="<%=String.valueOf(GeneralRequirements.UNLIMITED_CPU_COUNT)%>"/>

                  <c:set var="defaultCpuCount" value="${unlimitedResourceString}"/>

                  <c:if test="${maxCpuCountValue eq unlimitedCpuCount}">
                    <c:set var="maxCpuCountValue" value="${defaultCpuCount}"/>
                  </c:if>
                  <input type="text" name="maxCpuCount" value="${maxCpuCountValue}" maxlength="1024" id="maxCpuCount"
                         onfocus="if (this.value == '${defaultCpuCount}') this.value = '';"
                         onfocusout="if (this.value.empty()) this.value = '${defaultCpuCount}'"
                         style="width: 12rem"
                  />
                  <bs:smallNote>Leave the fields blank for unlimited CPU count</bs:smallNote>
                  <span class="error" id="errorCpuCounts"/>
                </td>
              </tr>
            </c:if>
            <c:if test="${intprop:getBoolean('teamcity.general.agent.memory.requirements.update.ui.enabled')}">
              <c:set var="memoryParameter" value="<%=GeneralRequirements.MEMORY_PARAMETER_NAME%>"/>
              <tr>
                <th rowspan="2"><label>Memory size:</label></th>
                <td>
                  <label for="minMemorySize" class="fixedLabel">from:</label>
                    <forms:autocompletionTextField name="minMemory" value="${requirementsBean.minMemory}" maxlength="1024" id="minMemory"
                                                   autocompletionSource="BS.GeneralRequirementsForm.createAutocompletionSource('${genralSettingsAutocompletionUrl}', '${memoryParameter}', 'minMemory')"/>
              </tr>
              <tr>
                <td>
                  <label for="maxMemorySize" class="fixedLabel">to:</label>
                  <forms:autocompletionTextField name="maxMemory" value="${requirementsBean.maxMemory}" maxlength="1024" id="maxMemory"
                                                 autocompletionSource="BS.GeneralRequirementsForm.createAutocompletionSource('${genralSettingsAutocompletionUrl}', '${memoryParameter}', 'maxMemory')"/>
                  <span class="error" id="memorySizeError"/>
                </td>
              </tr>
            </c:if>
          </table>

          <input type="hidden" id="updateGeneralRequirements" name="submitAction" value=""/>
          <c:if test="${!buildForm.readOnly}">
            <div class="saveButtonsBlock">
              <forms:submit name="submitButton" label="Save"/>
              <forms:saving/>
            </div>
          </c:if>
        </form>
      </div>
    </c:if>


    <div class="section noMargin">
      <h2 class="noBorder">Explicit Requirements</h2>
      <bs:smallNote>This page lists all requirements that build agents should meet to run your builds.<bs:help file="Configuring+Agent+Requirements"/></bs:smallNote>

      <c:if test="${not buildForm.readOnly}">
      <div>
        <admin:newRequirement linkText="Add new requirement"/>
      </div>
      </c:if>

      <admin:requirementsList requirements="${requirementsBean.requirements}" requirementsBean="${requirementsBean}" editable="${not buildForm.readOnly}"/>
    </div>


    <c:set var="runnerRequirements" value="${requirementsBean.runTypeRequirements}"/>
    <c:if test="${not empty runnerRequirements and fn:length(runnerRequirements) > 0}">
      <div class="section">
        <h2 class="noBorder">Build Steps Requirements <%--(${fn:length(runnerRequirements)})--%></h2>
        <bs:smallNote>Additional agent requirements imposed by the configured build steps</bs:smallNote>

        <div class="predefinedBlock" id="runner_requirements">
          <admin:requirementsList requirementsBean="${requirementsBean}" requirements="${runnerRequirements}" editable="false"/>
        </div>
    </c:if>


    <c:set var="featureRequirements" value="${requirementsBean.buildFeatureRequirements}"/>
    <c:if test="${not empty featureRequirements and fn:length(featureRequirements) > 0}">
      <div class="section">
        <h2 class="noBorder">Build Features Requirements <%--(${fn:length(featureRequirements)})--%></h2>
        <bs:smallNote>Additional agent requirements imposed by the configured build features</bs:smallNote>

        <div class="predefinedBlock">
          <admin:requirementsList requirementsBean="${requirementsBean}" requirements="${featureRequirements}" editable="false"/>
        </div>
    </c:if>


    <c:set var="undefinedParameters" value="${requirementsBean.undefinedParameters}"/>
    <c:if test="${not empty undefinedParameters}">
      <div class="section">
        <h2 class="noBorder">Implicit Requirements <%--(${fn:length(undefinedParameters)})--%></h2>
        <bs:smallNote>This section lists parameters used in configuration settings without actual values provided.<bs:help file="ImplicitAgentRequirements" preservePlus="true" /></bs:smallNote>

        <div class="predefinedBlock" id="implicit_requirements">
          <admin:editBuildTypeNavSteps settings="${buildForm.settings}"/>
          <l:tableWithHighlighting className="parametersTable">
            <tr style="background-color: var(--ring-secondary-background-color, #f7f9fa);">
              <th>Parameter Name</th>
              <th colspan="2">Parameter Source</th>
            </tr>
            <c:forEach items="${undefinedParameters}" var="e">
              <tr>
                <td class="name"><c:out value="${e.key}"/></td>
                <td class="value">
                  <c:set var="settingDescr" value="${e.value}"/>
                  <c:choose>
                  <c:when test="${settingDescr.type.name == 'ARTIFACTS' or settingDescr.type.name == 'BUILD_TYPE_OPTIONS'}">
                    <a href="<c:url value='${buildConfigSteps[0].url}'/>"><c:out value="${settingDescr.description}"/></a>
                  </c:when>
                  <c:when test="${settingDescr.type.name == 'VCS_ROOT'}">
                    <c:set var="vcsRoot" value="${settingDescr.additionalData}"/>
                    <admin:editVcsRootLink vcsRoot="${settingDescr.additionalData}" editingScope="none" cameFromUrl="${pageUrl}"><c:out value="${settingDescr.description}"/></admin:editVcsRootLink>
                  </c:when>
                  <c:when test="${settingDescr.type.name == 'CHECKOUT_RULES'}">
                    <a href="<c:url value='${buildConfigSteps[1].url}'/>"><c:out value="${settingDescr.description}"/></a>
                  </c:when>
                  <c:when test="${settingDescr.type.name == 'CHECKOUT_DIR'}">
                    <a href="<c:url value='${buildConfigSteps[1].url}'/>"><c:out value="${settingDescr.description}"/></a>
                  </c:when>
                  <c:when test="${settingDescr.type.name == 'LABEL_PATTERN'}">
                  <a href="<c:url value='${buildConfigSteps[5].url}'/>"><c:out value="${settingDescr.description}"/>a>
                    </c:when>
                    <c:when test="${settingDescr.type.name == 'BUILD_FEATURE'}">
                    <a href="<c:url value='${buildConfigSteps[5].url}'/>"><c:out value="${settingDescr.description}"/></a>
                    </c:when>
                    <c:when test="${settingDescr.type.name == 'BUILD_STEP'}">
                      <c:set var="stepName" value="${settingDescr.additionalData.name}"/>
                      <c:set var="stepType" value="${settingDescr.additionalData.runType.displayName}"/>
                      <c:url value='/admin/editRunType.html?init=1&id=${buildForm.settingsId}&runnerId=${settingDescr.additionalData.id}&cameFromUrl=${pageUrl}' var="stepUrl"/>
                    <a href="${stepUrl}"><c:out value="${settingDescr.description}"/></a>
                    </c:when>
                    <c:when test="${settingDescr.type.name == 'BUILD_FAILURE_CONDITION'}">
                    <a href="<c:url value='${buildConfigSteps[4].url}'/>"><c:out value="${settingDescr.description}"/></a>
                    </c:when>
                    <c:when test="${settingDescr.type.name == 'ARTIFACT_DEPENDENCY'}">
                    <a href="<c:url value='${buildConfigSteps[6].url}'/>"><c:out value="${settingDescr.description}"/></a>
                    </c:when>
                    <c:when test="${settingDescr.type.name == 'PARAMETER'}">
                    <a href="<c:url value='${buildConfigSteps[7].url}'/>#${settingDescr.additionalData}"><c:out value="${settingDescr.description}"/></a>
                    </c:when>
                    <c:when test="${settingDescr.type.name == 'REQUIREMENT'}">
                    <a href="<c:url value='${buildConfigSteps[8].url}'/>#${settingDescr.additionalData}">
                      <c:out value="${settingDescr.description}"/>
                    </a>
                    </c:when>
                    <c:otherwise><c:out value="${settingDescr.description}"/></c:otherwise>
                    </c:choose>
                </td>
                <c:set var="paramName" value="${e.key}"/>
                <c:set var="paramId" value='<%=ParameterInfo.makeParameterId((String)jspContext.getAttribute("paramName"))%>'/>
                <td class="edit"><a href="<c:url value='${buildConfigSteps[7].url}'/>#edit_${paramId}">define</a></td>
              </tr>
            </c:forEach>
          </l:tableWithHighlighting>
        </div>
      </div>
    </c:if>

    <div class="section">
      <h2 class="noBorder">Agent and Executor Compatibility</h2>
      <bs:smallNote>In this section you can see which executors and agents are compatible with the requirements and which are not.</bs:smallNote>

      <bs:buildTypeCompatibility compatibleAgents="${buildForm.settings}" project="${buildForm.project}"/>
    </div>

    <!--here go two popup dialogs-->

    <c:url var="editRequirementAction" value="/admin/editRequirements.html?id=${buildForm.settingsId}"/>
    <c:url var="autocompletionUrl" value="/agentParametersAutocompletion.html"/>
    <admin:editRequirementDialog
        editRequirementAction="${editRequirementAction}"
        autocompletionUrl="${autocompletionUrl}"
        dialogJsObject="BS.EditRequirementDialog"
        saveCommand="BS.RequirementsForm.saveRequirement()"
    />

    <script type="text/javascript">
      (function($) {
        $(document).ready(function() {
          var parsedHash = BS.Util.paramsFromHash('&');
          var name = parsedHash['addRequirement'];
          var val = parsedHash['value'];
          var reqType = parsedHash['type'];
          if (name && val && reqType) {
            BS.Util.setParamsInHash({}, '&', true);
            BS.EditRequirementDialog.showDialog(name, val, reqType)
          }
        });
      }(jQuery));

    </script>
  </jsp:attribute>
</admin:editBuildTypePage>
