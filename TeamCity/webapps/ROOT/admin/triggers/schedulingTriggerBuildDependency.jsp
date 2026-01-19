<%@ page import="jetbrains.buildServer.artifacts.RevisionRules" %>
<%@ page import="jetbrains.buildServer.serverSide.Branch" %>
<%@ page import="jetbrains.buildServer.serverSide.vcs.spec.AttributesBranchFiltersProperties" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<jsp:useBean id="dependencyTriggerBean" type="jetbrains.buildServer.controllers.admin.projects.triggers.DependencyBuildTriggerBean" scope="request"/>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.BasePropertiesBean" scope="request"/>
<c:set var="curDeps" value="${dependencyTriggerBean.currentSnapshotDependencies}"/>
<c:set var="buildDependencyFieldsStyle" value="${propertiesBean.properties['triggerBuildIfWatchedBuildChanges'] == null ? 'display:none' : '' }"/>
<c:set var="branchesConfigured" value="${buildForm.template or buildForm.branchesConfigured}"/>
<c:set var="isAttributesEnabled" value="<%= AttributesBranchFiltersProperties.isEnabledTriggers() %>"/>

<style type="text/css">
  .clickable-text {
    color:  var(--ring-link-color);
    cursor: pointer;
  }
</style>

<script type="text/javascript">

  window.ScheduledBuildTrigger = {};

  window.ScheduledBuildTrigger.chbxOnUpdate = function(chbx){
    if (chbx.checked) {
      $j('.buildDependencyFields').show();
      $j('#promoteWatchedBuild').prop('checked', true);
    } else {
      $j('.buildDependencyFields').hide();
    }

    BS.VisibilityHandlers.updateVisibility('buildTagField');
    BS.VisibilityHandlers.updateVisibility('buildBranchField');
  };
  window.ScheduledBuildTrigger.dependsOnUpdate = function(select){
    window.ScheduledBuildTrigger.updates(select.options[select.selectedIndex].value);
  };
  window.ScheduledBuildTrigger.updates = function(selectedId){
    var branchesConfigured = ${branchesConfigured};

    if (selectedId == undefined){
      return;
    }

    var showBranchField = function(branches) {
      var hasNonDefaultBranch = branches.length > 1;
      if (!hasNonDefaultBranch) {
        for (var i=0; i<branches.length; i++) {
          if (!branches[i].is_default) {
            hasNonDefaultBranch = true;
            break;
          }
        }
      }

      if (hasNonDefaultBranch || (branchesConfigured && window._curDeps[selectedId])) {
        // if selected build configuration has more than one branch or
        // branches configured in current build configuration and there is a snapshot dependency on the selected one
        $j('#buildBranchField').show();
        BS.BranchFilterHelperPopup.attachHandler('revisionRuleBuildBranch', ["branchPattern", "pullRequest"], [BS.BranchesPopup.createParams('${buildForm.settingsId}', 'branchFilter', 'ALL_BRANCHES'), ""]);
      } else {
        $j('#buildBranchField').hide();
      }

      BS.VisibilityHandlers.updateVisibility('buildBranchField');
      BS.MultilineProperties.updateVisible();
    };

    BS.AdminActions.listBranches(selectedId, showBranchField);

    BS.MultilineProperties.updateVisible();
  };
  window.ScheduledBuildTrigger.restDependsOnUpdate = function(){
    window.ScheduledBuildTrigger.updates($j('#dependsOn').val());
  }
</script>
<tr class="advancedSetting">
  <td colspan="2">
    <props:checkboxProperty name="triggerBuildIfWatchedBuildChanges" onclick="window.ScheduledBuildTrigger.chbxOnUpdate(this);"/>
    <label for="triggerBuildIfWatchedBuildChanges">Trigger only if the watched build changes</label><bs:help file="Configuring+Schedule+Triggers" anchor="BuildChanges"/>
  </td>
</tr>
<tr class="buildDependencyFields advancedSetting" style="${buildDependencyFieldsStyle}">
  <td class="_top _label"><label for="revisionRuleDependsOn">Watch for:</label></td>
  <td>
    <input type="hidden" id="dependsOn" name="prop:revisionRuleDependsOn" value="${propertiesBean.properties['revisionRuleDependsOn']}"/>
    <input type="hidden" id="dependsOnDefaultBranchExcluded"  value=""/>
    <input type="hidden" id="dependsOnHasBranches"  value=""/>
    <div id="dependsOnSelectorWrapper" style="width: 330px;"></div>
    <script type="text/javascript">
      {
        let selected = null;
        <c:choose>
          <c:when test="${not empty dependencyTriggerBean.selectedBuildType}">
            selected = {
              nodeType: 'bt',
                id: "${dependencyTriggerBean.selectedBuildType.externalId}",
            };
          </c:when>
          <c:when test="${not empty propertiesBean.properties['dependsOn']}">
            selected = {
              nodeType: 'bt',
                id: "${propertiesBean.properties['dependsOn']}",
            };
          </c:when>
        </c:choose>
        ReactUI.renderConnected(document.getElementById('dependsOnSelectorWrapper'), ReactUI.ProjectBuildTypeSelect, {
          excludedBuildTypes: [
            <c:forEach items="${dependencyTriggerBean.excludedBuildTypesIds}" var="bt">
              '${bt.externalId}',
            </c:forEach>
          ],
          selected,
          onSelect(item) {
            $j('#dependsOn').val(item.id);
            Promise.all([
              ReactUI.checkHasBranches(item.id).then(hasBranches => {
                $j('#dependsOnHasBranches').val(hasBranches);
              }),
              ReactUI.checkDefaultExcluded(item.id).then(defaultExcluded => {
                $j('#dependsOnDefaultBranchExcluded').val(defaultExcluded);
              }),
            ]).then(() => {
              window.ScheduledBuildTrigger.restDependsOnUpdate();
            });
          },
        });
      }
    </script>

    <span class="error" id="error_revisionRuleDependsOn"></span>
  </td>
</tr>
<tr class="buildDependencyFields advancedSetting" style="${buildDependencyFieldsStyle}">
  <td class="_label">&nbsp;</td>
  <td>
    <c:set var="lastSuccessful" value="<%=RevisionRules.LAST_SUCCESSFUL_NAME%>"/>
    <c:set var="lastFinished" value="<%=RevisionRules.LAST_FINISHED_NAME%>"/>
    <c:set var="lastPinned" value="<%=RevisionRules.LAST_PINNED_NAME%>"/>
    <c:set var="buildNumber" value="<%=RevisionRules.BUILD_NUMBER_NAME%>"/>
    <c:set var="buildTag" value="<%=RevisionRules.BUILD_TAG_NAME%>"/>

    <props:selectProperty name="revisionRule" style="width: 100%;" enableFilter="true" onchange="{
      if (this.options[this.selectedIndex].value == '${buildTag}') {
        $j('#buildTagField').show();
      } else {
        $j('#buildTagField').hide();
      }
      BS.VisibilityHandlers.updateVisibility('buildTagField');
    }">
      <props:option value="${lastFinished}">Last finished build</props:option>
      <props:option value="${lastSuccessful}">Last successful build</props:option>
      <props:option value="${lastPinned}">Last pinned build</props:option>
      <props:option value="${buildTag}">Last finished build with specified tag</props:option>
    </props:selectProperty>

    <c:set var="buildTag" value="<%=RevisionRules.BUILD_TAG_NAME%>"/>
    <div id="buildTagField" style="padding-top: 0.5em; ${propertiesBean.properties['revisionRule'] != buildTag ? 'display: none;' : ''}">
      <label for="revistionRuleBuildTag">Build tag:</label>
      <props:textProperty name="revistionRuleBuildTag" style="width: 22em;"/>
      <span class="error" id="error_revistionRuleBuildTag"></span>
    </div>

    <c:set var="specifiedBranch" value="${propertiesBean.properties['revisionRuleBuildBranch']}"/>
    <c:set var="defaultBranch" value="+:<%=Branch.DEFAULT_BRANCH_NAME%>"/>
    <div id="buildBranchField" style="padding-top: 0.5em; ${empty specifiedBranch or specifiedBranch == defaultBranch? 'display: none;' : ''}">
      <props:multilineProperty name="revisionRuleBuildBranch" style="width: 20.5em;" rows="1" cols="44" expanded="true" linkTitle="Build branch filter"/>
      <bs:smallNote>
        <c:choose>
          <c:when test="${isAttributesEnabled}">
            New-line delimited list of logical branch names with an optional "*" placeholder (+|-: &lt;name&gt;) or pull request conditions (+|-pr: &lt;properties&gt;).<bs:help file="Branch Filter"/>
          </c:when>
          <c:otherwise>
            Newline-delimited set of rules in the form of +|-:logical branch name (with an optional * placeholder).<bs:help file="Branch+Filter"/>
          </c:otherwise>
        </c:choose>
        <br>
        Set to empty value to use the same branch where the build is triggered.
        <br>
        Click the <span class="clickable-text" onclick="document.getElementById('handle_helper_revisionRuleBuildBranch').click()">Magic wand button</span> to invoke the filter expression editor
      </bs:smallNote>
    </div>

    <div style="padding-top: 0.5em;">
      <props:checkboxProperty name="promoteWatchedBuild"/>
      <label for="promoteWatchedBuild">Promote the watched build if there is a dependency (snapshot or artifact) on its build configuration</label>
    </div>

    <script type="text/javascript">
      window._curDeps = {};
      <c:forEach items="${curDeps}" var="dep">
      window._curDeps['${dep.externalId}'] = true;
      </c:forEach>
      window.ScheduledBuildTrigger.restDependsOnUpdate();
    </script>
  </td>
</tr>
