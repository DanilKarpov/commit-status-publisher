<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="runBuildBean" type="jetbrains.buildServer.controllers.RunBuildBean" scope="request"/>

<div id="comment-tab" style="display: none;" class="tabContent">
  <div class="${not empty runBuildBean.buildComment ? 'modifiedParam' : ''}">
    <textarea name="buildComment" rows="5" cols="46" class="commentTextArea" placeholder="&lt;Your comment here&gt;"><c:out value="${runBuildBean.buildComment}"/></textarea>
  </div>

  <authz:authorize projectId="${runBuildBean.buildType.projectId}" allPermissions="TAG_BUILD">
    <bs:_tagsEditingControl formId="runBuild" label="Tags" type="CustomBuild"/>

    <tags:_buildTypeTags buildType="${runBuildBean.buildType}"/>

    <bs:_applyToAllBuildsCheckbox prefix="tag"/>

    <c:if test="${fn:length(runBuildBean.buildType.dependencies) > 0}">
      <script type="text/javascript">
        $j("#runBuild .tagsApplyAll").show();
      </script>
    </c:if>
    <div style="padding-top: 10px;">
      <forms:checkbox name="addToFavorite" checked="${runBuildBean.addToFavorite}"/> <label for="addToFavorite">add build to favorites</label>
    </div>
  </authz:authorize>
</div>
