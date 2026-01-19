<%@ include file="/include.jsp" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:url value='/admin/pauseProject.html' var="actionUrl"/>
<%--@elvariable id="bean" type="jetbrains.buildServer.controllers.admin.projects.PauseProjectBean"--%>
<script type="text/javascript">
  BS.PauseProjectDialog.CommentData = ${bean.commentData};
</script>
<bs:modalDialog formId="pauseProjectForm"
                title="Change paused state of build configurations"
                action="${actionUrl}"
                closeCommand="BS.PauseProjectDialog.close();"
                saveCommand="BS.PauseProjectDialog.submit()">
  <c:choose>
    <c:when test="${bean.ableToEdit}">
      <p style="margin-top: 0"><em>Deactivates automatic triggers. Manual triggering and triggering via snapshot dependency is still possible</em></p>
      <bs:projectHierarchySelect containerId="pausedStatusTree"
                                 buildTypesHierarchy="${bean.buildTypes}"
                                 selectedBuildTypesMap="${bean.selectedBuildTypes}"
                                 selectedProjects="${bean.selectedProjects}"
                                 disableChildren="${false}"
                                 rootProjectSelected="${bean.rootProjectSelected}"
                                 includeRootProject="${bean.includeRootProject}">
        <jsp:attribute name="buildTypeDisplay">
          <bs:_buildTypePausedIcon buildType="${buildType}"/>
          <c:out value="${buildType.name}"/>
          <c:if test="${buildType.paused}">
            <c:if test="${not empty buildType.pauseComment and not empty buildType.pauseComment.comment}">
              <div class="hidden js-paused-data" id="${buildType.externalId}-hash" data-hash="${bean.commentHashes[buildType.externalId]}"></div>
              <span style="font-style: italic; color: #737577;">
                <c:out value="(${buildType.pauseComment.comment})"/>
              </span>
            </c:if>
          </c:if>
        </jsp:attribute>
        <jsp:attribute name="onChange_function_body">BS.PauseProjectDialog.processChange(evt);</jsp:attribute>
      </bs:projectHierarchySelect>
      <p class="attentionComment bulk-pause-dialog__warning hidden"></p>
      <label for="actionReason">Comment: </label>
      <textarea id="actionReason" name="actionReason"
                rows="3" cols="46" class="commentTextArea"
                onfocus="if (this.value == this.defaultValue) this.value = ''"
                onblur="if (this.value == '') this.value='&lt;your comment here&gt;'">&lt;your comment here&gt;</textarea>

      <authz:authorize allPermissions="CANCEL_BUILD">
        <div>
          <input type="checkbox" name="removeFromQueue" id="removeAllFromQueue"/>
          <label for="removeAllFromQueue">
            Cancel already queued builds if build configuration is paused
          </label>
        </div>
      </authz:authorize>
    </c:when>
    <c:otherwise>
      <div class="attentionComment">
        No build configurations found that can be paused or activated
      </div>
    </c:otherwise>
  </c:choose>
  <input type="hidden" name="currentProjectId" value="${bean.currentProject.externalId}"/>
  <div class="popupSaveButtonsBlock">
    <forms:submit label="Apply" disabled="${not bean.ableToEdit}"/>
    <forms:cancel onclick="BS.PauseProjectDialog.close()"/>
    <forms:saving id="pauseProjectProgressIcon"/>
  </div>
</bs:modalDialog>
