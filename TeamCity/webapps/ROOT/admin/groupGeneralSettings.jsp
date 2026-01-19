<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="editGroupBean" type="jetbrains.buildServer.controllers.admin.groups.EditGroupBean" scope="request"/>
<form action="${pageUrl}" id="editGroup" onsubmit="return BS.EditGroupForm.submit()" method="post">

<bs:messages key="groupUpdated"/>

<span class="error" id="error_editGroup"></span>
<bs:allUsersGroup group="${editGroupBean.groupDto}">
  <jsp:attribute name="ifAllUsersGroup">
    <div class="attentionComment">
      <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
      <strong><c:out value="${editGroupBean.groupDto.name}"/></strong> is a special group which contains all users and cannot be deleted.
      This group name and description cannot be changed too.
    </div>
  </jsp:attribute>
  <jsp:attribute name="ifUsualGroup">
    <authz:authorize anyPermission="DELETE_USERGROUP">
      <c:if test="${editGroupBean.groupDto.canDelete}">
        <input class="btn btn_mini submitButton" type="button" value="Delete Group" style="margin: 0 0 1em 0;"
               onclick="BS.GroupActions.deleteGroup('<bs:escapeForJs text="${editGroupBean.groupDto.key}" forHTMLAttribute="true"/>', ${editGroupBean.groupDto.allUsersCount}, function() {document.location.href='admin.html?item=groups'})"/>
        <div class="clr"></div>
      </c:if>
    </authz:authorize>
  </jsp:attribute>
</bs:allUsersGroup>

<c:set var="readOnly">
  <div class="general-property">
    <label class="tableLabel">Name:</label>
    <span><c:out value="${editGroupBean.groupDto.name}"/></span>
  </div>
  <div class="general-property">
    <label class="tableLabel" for="groupDescription">Description:</label>
    <span><c:out value="${editGroupBean.groupDto.description}"/></span>
  </div>
</c:set>
<c:set var="readOnlyMode" value="false"/>

<l:settingsBlock title="General">
  <div class="general-property">
    <label for="" class="tableLabel">Group Key:</label>
    <span><c:out value="${editGroupBean.group.key}"/></span>
  </div>

  <bs:allUsersGroup group="${editGroupBean.groupDto}">
    <jsp:attribute name="ifAllUsersGroup">
      ${readOnly}
      <c:set var="readOnlyMode" value="true"/>
    </jsp:attribute>
    <jsp:attribute name="ifUsualGroup">
      <c:choose>
        <c:when test="${not afn:permissionGrantedGlobally('CHANGE_USERGROUP')}">
          ${readOnly}
          <c:set var="readOnlyMode" value="true"/>
        </c:when>
        <c:otherwise>
          <div class="general-property">
            <label for="groupName" class="tableLabel">Name:<l:star/></label>
            <forms:textField name="groupName" className="longField" maxlength="256" value="${editGroupBean.groupName}"/>
            <span class="error" id="error_groupName"></span>
          </div>
          <div class="general-property">
            <label for="groupDescription" class="tableLabel">Description:</label>
            <forms:textField name="groupDescription" className="longField" maxlength="256" value="${editGroupBean.groupDescription}"/>
          </div>
        </c:otherwise>
      </c:choose>
    </jsp:attribute>
  </bs:allUsersGroup>
  <c:if test="${not editGroupBean.perProjectPermissionsEnabled}">
  <div class="general-property">
    <admin:perProjectRolesNote/>
    <forms:checkbox name="administrator" checked="${editGroupBean.administrator}"/> <label for="administrator">Group with administrative privileges (included users and groups will have administrative privileges too)</label>
    <c:if test="${editGroupBean.administratorStatusInherited}">
      <bs:smallNote>Administrative privileges are inherited from one or more parent groups</bs:smallNote>
    </c:if>
  </div>
  </c:if>
</l:settingsBlock>
<bs:userGroupAuthSettings groupBean="${editGroupBean}"/>

<l:settingsBlock title="Parent Groups">
  <admin:_attachToGroups attachToGroupsBean="${editGroupBean.attachGroupBean}" formId="editGroup"/>
</l:settingsBlock>

<c:if test="${editGroupBean.canBeMoved or not readOnlyMode or not serverSummary.perProjectPermissionsEnabled}">
  <input type="hidden" name="groupCode" value="<c:out value='${editGroupBean.groupDto.key}'/>"/>
  <input type="hidden" name="submitGroup" value=""/>

  <div class="saveButtonsBlock saveButtonsBlock_noborder">
    <forms:submit name="submitSettings" label="Save"/>
    <forms:cancel cameFromSupport="${editGroupBean.cameFromSupport}"/>
    <forms:saving/>
  </div>
</c:if>
</form>

<c:if test="${editGroupBean.canBeMoved or not readOnlyMode or not serverSummary.perProjectPermissionsEnabled}">
<forms:modified/>
<script type="text/javascript">
  BS.EditGroupForm.setUpdateStateHandlers({
    updateState: function() {
      BS.EditGroupForm.storeInSession();
    },
    saveState: function() {
      BS.EditGroupForm.submit();
    }
  });
</script>
</c:if>