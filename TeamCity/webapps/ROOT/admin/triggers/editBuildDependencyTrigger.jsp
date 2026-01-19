<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="admfn" uri="/WEB-INF/functions/admin" %>
<jsp:useBean id="dependencyTriggerBean" type="jetbrains.buildServer.controllers.admin.projects.triggers.DependencyBuildTriggerBean" scope="request"/>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.BasePropertiesBean" scope="request"/>
<c:set var="curDeps" value="${dependencyTriggerBean.currentSnapshotDependencies}"/>
<tr>
  <td colspan="2"><em>Finished Build Trigger will add a build to the queue after a build finishes in the selected configuration.</em></td>
</tr>
<script type="text/javascript">
  window.FinishBuildTrigger = {
    buildsWithBranches : []
  };
  window.FinishBuildTrigger.dependsOnUpdate = function(select){
    var selectedId = select.options[select.selectedIndex].value;
    if (selectedId == '') {
      return;
    }
    if (!window._curDeps[selectedId]) {
      BS.Util.show('snapshotDepWarn');
    } else {
      BS.Util.hide('snapshotDepWarn');
    }

    if (FinishBuildTrigger.buildsWithBranches && $j.inArray(selectedId, FinishBuildTrigger.buildsWithBranches) != -1) {
      BS.Util.show('finishTriggerBranchFilter');
      BS.MultilineProperties.updateVisible();
      if (window._branchFilter.length == 0) {
        $('branchFilter').value = '+:&lt;default&gt;';
      } else {
        $('branchFilter').value = window._branchFilter;
      }
    } else {
      BS.Util.hide('finishTriggerBranchFilter');
      $('branchFilter').value = '';
    };
  };
  window.FinishBuildTrigger.restDependsOnUpdate = function(selected){
    var selectedId = $j('#dependsOn').val();

    if (selectedId == '') {
      BS.Util.hide('snapshotDepWarn');
      return;
    }
    if (!window._curDeps[selectedId]) {
      BS.Util.show('snapshotDepWarn');
    } else {
      BS.Util.hide('snapshotDepWarn');
    }

    if ($j('#dependsOnHasBranches').val() == 'true' || window._branchFilter){
      BS.Util.show('finishTriggerBranchFilter');
      BS.MultilineProperties.updateVisible();
      if (window._branchFilter.length == 0) {
        $('branchFilter').value = $j('#dependsOnDefaultBranchExcluded').val() == 'false' ? '+:&lt;default&gt;'.replace('&lt;', '<').replace('&gt;', '>') : "";
      } else {
        $('branchFilter').value = window._branchFilter;
      }
    } else {
      $('branchFilter').value = '';
    }

  }
</script>
<tr>
  <td style="vertical-align: baseline;">
    <label for="dependsOn">Build configuration:</label>
  </td>
  <td style="vertical-align: baseline;">
    <input type="hidden" id="dependsOn" name="prop:dependsOn" value="${propertiesBean.properties['dependsOn']}"/>
    <input type="hidden" id="dependsOnDefaultBranchExcluded"  value=""/>
    <input type="hidden" id="dependsOnHasBranches"  value=""/>
    <div id="dependsOnSelectorWrapper" style="width: 330px;"></div>
    <script type="text/javascript">
      {
        const excludedBuildTypes = [];
        <c:forEach items="${dependencyTriggerBean.excludedBuildTypesIds}" var="bt">
          excludedBuildTypes.push('${bt.externalId}');
        </c:forEach>
        ReactUI.renderConnected(document.getElementById('dependsOnSelectorWrapper'), ReactUI.ProjectBuildTypeSelect, {
          excludedBuildTypes,
          <c:if test="${not empty dependencyTriggerBean.selectedBuildType}">
            selected: {
              nodeType: 'bt',
              id: "${dependencyTriggerBean.selectedBuildType.externalId}",
            },
          </c:if>
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
              window.FinishBuildTrigger.restDependsOnUpdate();
            });
          }
        })
      }
    </script>
    <div id="snapshotDepWarn" style="display: none; margin-top: 0.3em;"><bs:buildStatusIcon type="red-sign" className="warningIcon"/>
      There is no snapshot dependency on the selected build configuration.<bs:help file="Configuring Finish Build Trigger"/></div>
    <span class="error" id="error_dependsOn"></span>
    <script type="text/javascript">
      window._curDeps = {};
      <c:forEach items="${curDeps}" var="dep">
      window._curDeps['${dep.externalId}'] = true;
      </c:forEach>
      window._dependsOn = "${propertiesBean.properties['dependsOn']}";
      window._branchFilter = "${util:forJS(propertiesBean.properties['branchFilter'], false, false)}";
      window.FinishBuildTrigger.restDependsOnUpdate();
    </script>
  </td>
</tr>
<tr>
  <td class="noBorder">&nbsp;</td>
  <td class="noBorder">
    <props:checkboxProperty name="afterSuccessfulBuildOnly" checked="${propertiesBean.properties['afterSuccessfulBuildOnly']}"/>
    <label for="afterSuccessfulBuildOnly">Trigger after successful build only</label>
  </td>
</tr>
<tbody id="finishTriggerBranchFilter" style="${empty propertiesBean.properties['dependsOn'] ? 'display: none;' : ''}">
  <c:set var="buildTypeIdsFunc" scope="request">
    function() {
    return [$j('#dependsOn').val()];
    }
  </c:set>
  <jsp:include page="branchFilter.jsp"/>
</tbody>
