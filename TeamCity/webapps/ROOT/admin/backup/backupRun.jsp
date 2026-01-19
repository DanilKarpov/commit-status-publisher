<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>

<jsp:useBean id="backupPath" type="java.lang.String" scope="request"/>
<jsp:useBean id="settings" type="jetbrains.buildServer.serverSide.maintenance.BackupSettings" scope="request"/>
<jsp:useBean id="current" type="jetbrains.buildServer.controllers.admin.backup.BackupCurrentInfo" scope="request"/>

<div id="container">

<form method="post" action="<c:url value='/admin/backupPage.html'/>" id="BackupRunForm" onsubmit="return false;">

  <c:if test="${current.canStartBackup}">
  </c:if>
  
  <h2>Start backup</h2>

  <div <c:if test="${not current.canStartBackup}">class="disabled"</c:if>>

    <table class="runnerFormTable">
      <tr>
        <th><label for="config.fileName">Backup file:<l:star/></label></th>
        <td>
          <forms:textField name="settings.fileName" value="${settings.fileName}" style="width: 25em" maxlength="240" onchange="BS.BackupRunForm.justModified()" disabled="${not current.canStartBackup}" /> &nbsp;
          <forms:checkbox name="settings.addTimestampSuffix" checked="${settings.addTimestampSuffix}" onclick="BS.BackupRunForm.justModified()" disabled="${not current.canStartBackup}" /> <label for="settings.addTimestampSuffix" disabled="${not current.canStartBackup}">add timestamp suffix</label>
          <span class="error" id="fileNameError" style="white-space: pre"></span>
          <bs:smallNote>Directory for backup files: <strong><c:out value='${backupPath}'/></strong><br/></bs:smallNote>
        </td>
      </tr>
      <tr>
        <th>Backup scope:<bs:help file="CreatingBackupfromTeamCityWebUI-backup_scope"/></th>
        <td>
          <forms:select name="settings.preset" onchange="BS.BackupRunForm.refreshPresetPanels()" disabled="true">
            <forms:option value="DCU">Basic</forms:option>
            <forms:option value="DCULP">All except build artifacts</forms:option>
            <forms:option value="X">Custom</forms:option>
          </forms:select><br/>
          <ul id="noteForPresetCD" class="presetDescription hidden">
            <li>database</li>
            <li>server settings, projects and builds configurations, plugins</li>
            <li>supplementary data (settings history, triggers states, plugins data, etc.)</li>
          </ul>
          <ul id="noteForPresetCDLP" class="presetDescription hidden">
            <li>database</li>
            <li>server settings, projects and builds configurations, plugins</li>
            <li>supplementary data (settings history, triggers states, plugins data, etc.)</li>
            <li>build logs</li>
            <li>personal builds changes</li>
          </ul>
          <div id="customScopeCheckBoxes" class="presetDescriptionCustom hidden">
            <forms:checkbox name="settings.customIncludeDatabase" checked="${settings.customIncludeDatabase}" onclick="BS.BackupRunForm.justModified();" disabled="${not current.canStartBackup}" /> <label for="settings.customIncludeDatabase" class="<c:if test='${not current.canStartBackup}'>disabled</c:if>" >database</label> <br/>
            <forms:checkbox name="settings.customIncludeConfiguration" checked="${settings.customIncludeConfiguration}" onclick="BS.BackupRunForm.justModified();" disabled="${not current.canStartBackup}" /> <label for="settings.customIncludeConfiguration" class="<c:if test='${not current.canStartBackup}'>disabled</c:if>" >server settings, projects and builds configurations (including secure values), plugins</label> <br/>
            <forms:checkbox name="settings.customIncludeSupplementaryData" checked="${settings.customIncludeSupplementaryData}" onclick="BS.BackupRunForm.justModified();" disabled="${not current.canStartBackup}" /> <label for="settings.customIncludeSupplementaryData" class="<c:if test='${not current.canStartBackup}'>disabled</c:if>" >supplementary data (settings history, triggers states, plugins data, etc.)</label> <br/>
            <forms:checkbox name="settings.customIncludeBuildLogs" checked="${settings.customIncludeBuildLogs}" onclick="BS.BackupRunForm.justModified();" disabled="${not current.canStartBackup}" /> <label for="settings.customIncludeBuildLogs" class="<c:if test='${not current.canStartBackup}'>disabled</c:if>" >build logs<bs:help file="CreatingBackupfromTeamCityWebUI-backup_scope" shortHelp="including this option is not recommended as this can significantly increase backup size and time, consider backing up with artifacts instead"/></label> <br/>
            <forms:checkbox name="settings.customIncludePersonalChanges" checked="${settings.customIncludePersonalChanges}" onclick="BS.BackupRunForm.justModified();" disabled="${not current.canStartBackup}" /> <label for="settings.customIncludePersonalChanges" class="<c:if test='${not current.canStartBackup}'>disabled</c:if>" >personal builds changes</label>
          </div>
          <bs:smallNote>Note: Build artifacts as well as running builds and build queue state are <bs:helpLink file="DataBackup-BackingUpData">not included</bs:helpLink> in the backup.</bs:smallNote>
        </td>
      </tr>
    </table>

    <div class="error" id="unexpectedError" align="left"></div>

    <c:if test="${current.oldVcsChangesAreBeingConverted}">
      <br/>
      <p class="attentionComment">
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>TeamCity is currently optimizing VCS-related data in the database for better backup/restore performance.
        It is not recommended to use backup files produced while this process is running for <bs:helpLink file="Projects Import">project import</bs:helpLink> as projects may not have all VCS-related data after the import.
        <br/>
        Progress: <b>${current.oldVcsChangesProgress}%</b> done.
      </p>
    </c:if>

    <c:if test="${current.databaseIsHSQL}">
      <br/>
      <p class="attentionComment">
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>The system is currently configured to work with an internal database (HSQL), which has limitations and is <bs:helpLink file="Setting up an External Database">not recommended for production use</bs:helpLink>.
        As a result, backup of a large database can cause an <strong>OutOfMemory</strong> error.
        See the <bs:helpLink file='TeamCity+Data+Backup'>TeamCity Data Backup</bs:helpLink> page for details.
      </p>
    </c:if>

    <div class="saveButtonsBlock">
      <forms:submit id="submitStartBackup" name="submitStartBackup" label="Start Backup" onclick="BS.BackupRunForm.doSubmitStart()" disabled="${not current.canStartBackup}"/>
      <forms:saving id="startBackup"/>
      <c:if test="${current.disabledNow}">
        <br>
        Cannot start backup process right now: ${current.disabledReason}
      </c:if>
    </div>

  </div>

  <c:if test="${not current.canStartBackup and not current.backupInProgress and not current.disabledNow}">
    <div>
      Cannot start backup process: ${current.disabledReason}
    </div>
  </c:if>

  <br/>


  <c:if test="${current.showReport}">

    <h2>
      <c:choose>
        <c:when test="${current.backupInProgress}">
          Current
        </c:when>
        <c:otherwise>
          The last
        </c:otherwise>
      </c:choose>
      backup report
    </h2>

    <bs:refreshable containerId="backupProgress" pageUrl="${pageUrl}">

      <table style="margin-top: 1em">

        <tr>
          <td>Backup file:</td>
          <td>
            <c:if test="${current.canBeDownloaded}">
              <a href="<c:url value='${current.downloadURL}'/>"><span class="mono mono-12px"><c:out value="${current.report.zipFileName}"/></span></a>
            </c:if>
            <c:if test="${not current.canBeDownloaded}">
              <span class="mono mono-12px"><c:out value="${current.report.zipFileName}"/></span>
            </c:if>
            <c:if test="${current.done}">
              &emsp; (&thinsp;${current.archiveSizeForHuman}&thinsp;)
            </c:if>
          </td>
        </tr>

        <c:forEach var="record" items="${current.stageRecords}">
          <c:if test='${record.state != "NotSelected"}'>
            <tr>
              <td nowrap="true" style="padding-right:0.5cm">
                ${record.stage.phrase}:
              </td>
              <td>
                <c:choose>
                  <c:when test='${record.state == "InProgress"}'>
                    <span class="running">${record.state.decsription}</span>
                    <c:if test='${record.stage.objectsAreTables or record.stage.objectsAreFiles}'>
                      (${record.progress}% in <bs:printTime time="${record.timeSpent/1000}"/><c:if
                        test='${record.stage.objectsAreTables}'>, exporting table (${record.objectsProcessed+1} out of ${record.objectsEstimated}) <i>${record.currentObjectName}</i></c:if>)
                    </c:if>
                  </c:when>
                  <c:when test='${record.state == "Done"}'>
                    ${record.state.decsription}
                    in <bs:printTime time="${record.timeSpent/1000}"/><c:if test='${record.stage == "Database"}'>,
                                                                         exported ${record.objectsProcessed} tables
                                                                      </c:if>
                  </c:when>
                  <c:when test='${record.state == "Failed"}'>
                    <span class="error-hl">${record.state.decsription}</span>
                    <c:if test="${current.hasExceptions}">
                      <p>
                        <c:forEach var="ex" items="${current.exceptions}">
                          <span class="error-details">
                            <c:forEach var="exm" items="${ex}" varStatus="vs">
                              <c:if test="${not vs.first}"> &nbsp;&nbsp;&nbsp; caused by </c:if>
                              <span class="mono mono-12px">${exm.a}:</span>  <c:out value="${exm.b}" escapeXml="true"/><br/>
                            </c:forEach>
                          </span>
                        </c:forEach>
                      </p>
                    </c:if>
                  </c:when>
                  <c:otherwise>
                    ${record.state.decsription}
                  </c:otherwise>
                </c:choose>
              </td>
            </tr>
          </c:if>
        </c:forEach>
      </table>

      <c:if test='${current.report.overallStatus == "Done" or current.report.overallStatus == "Cancelled" or current.report.overallStatus == "Failed"}'>
        <p>
          <c:choose>
            <c:when test='${current.report.overallStatus == "Done"}'>Backup completed successfully </c:when>
            <c:when test='${current.report.overallStatus == "Cancelled"}'>Backup canceled by user </c:when>
            <c:when test='${current.report.overallStatus == "Failed"}'>Backup <span class="error-hl">failed </span> </c:when>
          </c:choose>
          in <bs:printTime time="${current.report.timeSpent/1000}"/>
        </p>
      </c:if>

      <c:if test="${current.backupInProgress}">
        <div class="saveButtonsBlock">
          <forms:submit type="button"
                        label="Stop current backup"
                        id="submitStopBackup" name="submitStopBackup"
                        onclick="return BS.BackupRunForm.doSubmitStop()"
                        disabled="${!current.backupInProgress || current.cancelling}"/>
          <forms:saving id="stopBackup"/>
        </div>
      </c:if>

      <script type="text/javascript">
        <c:if test="${current.backupInProgress}">
        BS.BackupRunForm.backupInProgress();
        </c:if>
        <c:if test="${not current.backupInProgress}">
        BS.BackupRunForm.backupStopped();
        </c:if>
      </script>
      
    </bs:refreshable>

  </c:if>

</form>
</div>

<script type="text/javascript">
  BS.BackupRunForm.init2(${current.canStartBackup}, '${settings.preset}');
</script>
