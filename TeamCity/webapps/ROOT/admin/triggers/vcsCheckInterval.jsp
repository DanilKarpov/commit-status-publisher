<%@ include file="/include.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<tr id="checkIntervalWarning" style="display: none;">
  <td>
    <script type="text/javascript">
      window.checkCheckInterval = function() {
        $('checkIntervalWarning').hide();

        if ($('quietPeriod2').checked || $('quietPeriod3').checked) {
          $('checkIntervalWarning').show();
        }
        BS.MultilineProperties.updateVisible();
      }
    </script>
    <c:if test="${not empty slowVcsRoots}">

    <div class="smallNoteAttention">

      <bs:buildStatusIcon type="red-sign" className="warningIcon"/>The following VCS root<bs:s val="${fn:length(slowVcsRoots)}"/> recently prevented build from triggering by VCS trigger
      due to large checking for changes interval (bigger or equal to quiet period):<bs:help file="Server+Health" anchor="TooSmallQuietPeriod"/>

      <ul>
        <c:forEach items="${slowVcsRoots}" var="vcsRoot">
          <li><admin:vcsRootName vcsRoot="${vcsRoot}" editingScope="none" cameFromUrl="${buildForm.cameFromSupport.cameFromUrl}"/>: ${vcsRoot.modificationCheckInterval} seconds</li>
        </c:forEach>
      </ul>
    </div>

    </c:if>

  </td>
</tr>
