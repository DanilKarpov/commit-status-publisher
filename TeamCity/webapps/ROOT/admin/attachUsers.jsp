<%@include file="/include-internal.jsp"%>
<jsp:useBean id="attachUsersBean" type="jetbrains.buildServer.controllers.admin.groups.AttachUsersBean" scope="request"/>

<c:url var="actionUrl" value="/admin/attachUsersToGroup.html"/>
<bs:refreshable containerId="attachUsersToGroupContainer" pageUrl="${actionUrl}">
  <bs:modalDialog formId="attachUsersToGroup"
                  title="Assign Users to Group"
                  action="${actionUrl}"
                  closeCommand="BS.AttachUsersToGroupDialog.close()"
                  saveCommand="BS.AttachUsersToGroupDialog.findUsers()">
    <bs:refreshable containerId="userListRefreshable" pageUrl="${actionUrl}">
      <div class="actionBar">
        <label for="keyword">Find:</label>
        <forms:textField name="keyword" size="20" maxlength="1024" value="${attachUsersBean.keyword}"/>
        <forms:filterButton/>
        <c:if test="${not empty attachUsersBean.keyword}"><forms:resetFilter resetHandler="return BS.AttachUsersToGroupDialog.resetFilter();"/></c:if>
        <forms:saving id="findProgress" className="progressRingInline"/>
      </div>

      <c:set var="foundUsers" value="${attachUsersBean.foundUsers}"/>
      <c:set var="foundUsersNum" value="${fn:length(foundUsers)}"/>

      <c:if test="${not attachUsersBean.filterSubmitted}">
        <p class="note">Users can be found by first letters in their name or email.</p>
      </c:if>
      <c:if test="${attachUsersBean.filterSubmitted}">
        <p class="note">
          Found <strong>${foundUsersNum}</strong> user<bs:s val="${foundUsersNum}"/>
          <c:if test="${attachUsersBean.showFoundUsersNote}">Users already included to this group are not shown.</c:if>
        </p>
        <div class="userListContainer custom-scroll">
          <c:if test="${foundUsersNum > 0}">
            <table class="userList">
              <tr>
                <th class="checkbox">
                  <forms:checkbox
                      name="selectAll"
                      onmouseover="BS.Tooltip.showMessage(this, {shift: {x: 10, y: 20}, delay: 600}, 'Click to select / unselect all users')"
                      onmouseout="BS.Tooltip.hidePopup()"
                      onclick="if (this.checked) BS.AttachUsersToGroupDialog.selectAll(true); else BS.AttachUsersToGroupDialog.selectAll(false)"/>
                </th>
                <th class="username">Username</th>
                <th>Name</th>
                <authz:authorize anyPermission="VIEW_USER_PROFILE, CHANGE_USER">
                  <th class="email">
                    <bs:allEmails users="${foundUsers}"/>
                    Email
                  </th>
                </authz:authorize>
              </tr>
            <c:forEach items="${foundUsers}" var="user">
              <tr>
                <td class="checkbox"><forms:checkbox name="userId" value="${user.id}"
                                                     disabled="${currentUser.id == user.id and not attachUsersBean.canAddCurrentUser}"/></td>
                <td><bs:editUserLink user="${user}"/></td>
                <td><bs:avatar user="${user}"/><c:out value="${user.name}"/></td>
                <authz:authorize anyPermission="VIEW_USER_PROFILE, CHANGE_USER">
                  <td><c:out value="${user.email}"/></td>
                </authz:authorize>
              </tr>
            </c:forEach>
            </table>
          </c:if>
        </div>

        <input type="hidden" name="groupCode" value="<c:out value='${attachUsersBean.group.key}'/>"/>
        <input type="hidden" name="submitAction" value=""/>

        <c:if test="${foundUsersNum > 0}">
          <div class="popupSaveButtonsBlock">
            <forms:submit type="button" label="Add to group" onclick="BS.AttachUsersToGroupDialog.submit()"/>
            <forms:cancel onclick="BS.AttachUsersToGroupDialog.close()"/>
            <forms:saving id="attachProgress"/>
          </div>
        </c:if>
      </c:if>
    </bs:refreshable>
  </bs:modalDialog>
</bs:refreshable>
