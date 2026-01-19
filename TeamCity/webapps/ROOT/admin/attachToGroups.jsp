<%@include file="/include-internal.jsp"%>
<jsp:useBean id="attachToGroupsBean" type="jetbrains.buildServer.controllers.admin.groups.AttachToGroupsBean" scope="request"/>

<c:url var="actionUrl" value="/admin/attachToGroups.html"/>
<bs:refreshable containerId="attachToGroupsContainer" pageUrl="${actionUrl}">
<bs:modalDialog formId="attachToGroups" title="Add to Groups" action="${actionUrl}" closeCommand="BS.AttachToGroupsDialog.close()" saveCommand="BS.AttachToGroupsDialog.submit()" dialogClass="modalDialog_small">
  <c:choose>
    <c:when test="${not attachToGroupsBean.attachNewGroup && not attachToGroupsBean.attachUsers && attachToGroupsBean.groupToAttach == null}">
      <span class="error" style="margin-left: 0;">The group you selected to attach does not exist anymore.</span>
    </c:when>
    <c:otherwise>

      <admin:_attachToGroups attachToGroupsBean="${attachToGroupsBean}" formId="attachToGroups"/>

      <div class="popupSaveButtonsBlock">
        <forms:submit label="Apply"/>
        <forms:cancel onclick="BS.AttachToGroupsDialog.close()"/>
        <forms:saving id="attachProgress"/>
      </div>

      <c:choose>
        <c:when test="${attachToGroupsBean.attachUsers}">
          <c:forEach var="user" items="${attachToGroupsBean.usersToAttach}">
            <input type="hidden" name="userId" value="${user.id}"/>
          </c:forEach>
        </c:when>
        <c:when test="${not attachToGroupsBean.attachNewGroup}">
          <input type="hidden" name="groupCode" value="<c:out value='${attachToGroupsBean.groupToAttach.key}'/>"/>
        </c:when>
      </c:choose>

    </c:otherwise>
  </c:choose>

</bs:modalDialog>
</bs:refreshable>