<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="updateOption" type="jetbrains.buildServer.updates.UpdateOption" scope="request"/>

<c:set var="url" value="/admin/update.html?version=${updateOption.version.version}"/>
<bs:refreshable containerId="updateState_${updateOption.version.version}" pageUrl="${url}">
  <div>
    <c:choose>
      <c:when test="${updateOption.readyForUpdate}">
        New version was downloaded, ready for update.<bs:help file="Upgrade-AutomaticUpdate"/>
        <div>
          <c:set var="helpLink"><bs:help file="Upgrade-AutomaticUpdate"/></c:set>
          <c:if test="${not empty updateOption.preparingWarning}">
            <forms:attentionComment>
              ${updateOption.preparingWarning}
            </forms:attentionComment>
          </c:if>
          <input class="btn" type="button" name="download" value="Update"
                 onclick="BS.TeamCityUpdater.openUpdateDialog(
                   '${updateOption.version.version}',
                   '${updateOption.fullVersion}',
                   '<bs:escapeForJs forHTMLAttribute="true" text="${helpLink}"/>'); return false" style="margin-top: 0.5em"/>
        </div>
      </c:when>
      <c:when test="${updateOption.preparingForUpdate}">
        <forms:progressRing id="preparingForUpdate_${updateOption.version.version}" className="progressRingSubmitBlock" progressTitle="Preparing for update..."/>
        Preparing for auto-update: ${updateOption.preparingProgress}
        <script type="text/javascript">
          BS.TeamCityUpdater.scheduleRefresh('${updateOption.version.version}');
        </script>
      </c:when>
      <c:otherwise>
          <c:set value="Download update" var="btnName"/>
          <c:choose>
            <c:when test="${updateOption.preparingFailedReason != null}">
              Failed to prepare for update: ${updateOption.preparingFailedReason} <br/>
              <c:set value="Retry" var="btnName"/>
            </c:when>
            <c:otherwise>
              This update can be installed automatically.<bs:help file="Upgrade-AutomaticUpdate"/><br/>
            </c:otherwise>
          </c:choose>
          <input id="prepareBtn_${updateOption.version.version}" class="btn" type="button" name="download" value="${btnName}"
                 onclick="BS.TeamCityUpdater.prepareForUpdate('${updateOption.version.version}'); return false;" style="margin-top: 0.5em"/>
          <forms:saving id="prepareBtnProgress_${updateOption.version.version}" className="progressRingInline"/>
      </c:otherwise>
    </c:choose>
  </div>
</bs:refreshable>
