<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="now" class="java.util.Date"/>
<jsp:useBean id="cleanupPoliciesForm"
             type="jetbrains.buildServer.controllers.admin.cleanup.CleanupPoliciesForm" scope="request"/>

<h2>Settings<bs:help file="Clean-Up#Server+Clean-up+Settings"/></h2>

<table class="runnerFormTable">
  <tr>
    <th>Periodic clean-up:</th>
    <td>
      <%@ include file="_cleanupEnableDisable.jspf" %>
    </td>
  </tr>
</table>

<%@ include file="_cleanupPoliciesForm.jspf" %>

<h2 class="cleanUp">Disk usage</h2>
<table class="runnerFormTable">
  <tr>
    <td>
      <div>
        <span id="freeSpaceHolder">
          Updating... <forms:progressRing className=" "/>
        </span>
        <a href="<c:url value='admin.html?item=diskUsage'/>">View disk usage report &raquo;</a>
      </div>
    </td>
  </tr>
</table>
<script type="text/javascript">
  $j(BS.Cleanup.updateOverallDiskUsage);
</script>

<c:if test="${cleanupPoliciesForm.ignoreDeletedEntities}">
  <c:set var="cleanupErrorsReportLink" value="admin.html?item=healthStatus#minSeverity=ERROR&scopeProjectId=__GLOBAL__&selectedCategoryId=CleanupErrorsCategory"/>
  <div class="attentionComment">
    <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
    Due to <bs:helpLink file="Common+Problems#%22Critical+error+in+configuration+file%22+errors">critical configuration errors</bs:helpLink>,
    TeamCity cannot clean up the data of deleted projects and build configurations.
    See the <a href="<c:url value='${cleanupErrorsReportLink}'/>">server health report</a>.
  </div>
</c:if>

<c:if test="${cleanupPoliciesForm.hasExtensionErrors()}">
  <c:set var="extensionsErrorsReportLink" value="admin.html?item=healthStatus#minSeverity=WARN&scopeProjectId=__GLOBAL__&selectedCategoryId=CleanupExtensionsErrorsCategory"/>
  <div class="attentionComment">
    <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
    Errors occurred when calling clean-up extensions.
    See the <a href="<c:url value='${extensionsErrorsReportLink}'/>">server health report</a>.
  </div>
</c:if>