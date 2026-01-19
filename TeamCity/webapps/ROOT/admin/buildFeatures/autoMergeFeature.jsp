<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<jsp:useBean id="bean" class="jetbrains.buildServer.controllers.admin.buildFeatures.autoMerge.AutoMergeConstants"/>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>

<script type="text/javascript">
  $j(document).ready(function() {

    function updateRunPolicyTooltipVisibility(currentValue) {
      var tooltipAfterBuildFinish = $j('#runPolicySetting .jsRunAfterBuildFinish');
      var tooltipBeforeBuildFinish = $j('#runPolicySetting .jsRunBeforeBuildFinish');
      var showBeforeBuildFinish = ('${bean.runPolicyBeforeBuildFinish}' === currentValue);
      if (showBeforeBuildFinish) {
        tooltipAfterBuildFinish.hide();
        tooltipBeforeBuildFinish.show();
      } else {
        tooltipAfterBuildFinish.show();
        tooltipBeforeBuildFinish.hide();
      }
    }
    var selected = $j('#runPolicySetting select option:selected').val();

    updateRunPolicyTooltipVisibility(selected);

    $j('#runPolicySetting select').on('change', function(e) {
      updateRunPolicyTooltipVisibility(e.target.value);
    });
  });
</script>

<tr>
  <td colspan="2">
    <em>This build feature tracks builds in branches matched by a given filter and merges them into a specified destination branch if the build satisfies a certain merge condition.</em><bs:help file="Automatic+Merge"/>
  </td>
</tr>
<tr class="noBorder">
  <th><label for="${bean.srcBranchFilterKey}">Watch builds in branches:<l:star/></label><bs:help file="Automatic+Merge"/></th>
  <td>
    <c:set var="note">
    Newline-delimited set of rules in the form of +|-:logical branch name (with an optional * placeholder)<bs:help file="Branch+Filter"/>
    </c:set>
    <props:multilineProperty name="${bean.srcBranchFilterKey}" linkTitle="Branch filter" cols="60" rows="3" className="longField" expanded="true" note="${note}"/>
    <span class="error" id="error_${bean.srcBranchFilterKey}"/>

    <script type="text/javascript">
    BS.BranchesPopup.attachHandler('${buildForm.settingsId}', '${bean.srcBranchFilterKey}');
    </script>
  </td>
</tr>
<tr class="noBorder">
  <th><label for="${bean.dstBranchKey}">Merge into branch:<l:star/></label><bs:help file="Automatic+Merge"/></th>
  <td>
    <props:textProperty name="${bean.dstBranchKey}" className="longField"/>
    <span class="smallNote">
      A logical name of the destination branch<bs:help file="logicalBranchName"/>.
      A corresponding VCS branch must be present in a repository.
    </span>
    <span class="smallNote">
      Note: if destination branch is set via parameter then
      anyone who can run custom builds can override destination branch
    </span>
    <span class="error" id="error_${bean.dstBranchKey}"/>
    <script type="text/javascript">
      BS.BranchesPopup.attachHandler('${buildForm.settingsId}', '${bean.dstBranchKey}', 'singleBranch');
      <c:if test="${buildForm.vcsRootsBean.defaultExcluded}">
      if ($('${bean.dstBranchKey}').value == '<default>' && $('${bean.srcBranchFilterKey}').value == '') {
        <%--
        when new feature is added (branch filter is empty) and default branch is excluded,
        make the branch empty in order to ask for a valid non-default branch
         --%>
        $('${bean.dstBranchKey}').value = '';
      }
      </c:if>
    </script>
  </td>
</tr>
<tr class="noBorder">
  <th><label for="${bean.messageKey}">Merge commit message:<l:star/></label></th>
  <td>
    <props:textProperty name="${bean.messageKey}" className="longField"/>
    <span class="error" id="error_${bean.messageKey}"/>
  </td>
</tr>
<tr class="noBorder">
  <th>Perform merge if:</th>
  <td>
    <props:radioButtonProperty id="buildConditionSuccessful" name="${bean.buildCondition}" value="${bean.buildConditionSuccessful}"/>
    <label for="buildConditionSuccessful">build is successful</label>
    <br/>
    <props:radioButtonProperty id="buildConditionNoNewTests" name="${bean.buildCondition}" value="${bean.buildConditionNoNewTests}"/>
    <label for="buildConditionNoNewTests">no new tests failed comparing to destination branch</label>
  </td>
</tr>
<tr class="noBorder">
  <th><label for="${bean.mergePolicyKey}">Merge policy:</label></th>
  <td>
    <props:selectProperty name="${bean.mergePolicyKey}">
      <props:option value="${bean.mergePolicyAlwaysCreateMergeCommit}">Always create merge commit</props:option>
      <props:option value="${bean.mergePolicyFastForward}">Use fast-forward merge if possible</props:option>
    </props:selectProperty>
    <span class="smallNote">Note: not supported for Perforce VCS roots</span>
  </td>
</tr>
<tr class="noBorder" id="runPolicySetting">
  <th><label for="${bean.runPolicyKey}">Run policy:</label></th>
  <td>
    <props:selectProperty name="${bean.runPolicyKey}">
      <props:option value="${bean.runPolicyAfterBuildFinish}">Merge after build finish</props:option>
      <props:option value="${bean.runPolicyBeforeBuildFinish}">Merge before build finish</props:option>
    </props:selectProperty>
    <span class="smallNote jsRunAfterBuildFinish">
      In this case merge is performed after the build finish. The duration of the merge will not affect the build duration.
      Dependent builds can start even though merge is not done yet.
    </span>
    <span class="smallNote jsRunBeforeBuildFinish">
      Build will not be marked as finished until merge is done. Dependent builds won't start until merge finishes.
    </span>
  </td>
</tr>
