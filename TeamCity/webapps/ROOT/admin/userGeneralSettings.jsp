<%@ page import="jetbrains.buildServer.controllers.admin.users.AdminEditUserController" %>
<%@ page import="jetbrains.buildServer.controllers.emailVerification.EmailVerificationController" %>
<%@ page import="static jetbrains.buildServer.auth.SessionModel.KEY_ENABLE_LOGOUT_ALL_SESSIONS" %>
<%@ page import="jetbrains.buildServer.controllers.profile.UserProperty" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop" %>
<%@ taglib prefix="profile" tagdir="/WEB-INF/tags/userProfile"%>
<jsp:useBean id="adminEditUserForm" type="jetbrains.buildServer.controllers.admin.users.AdminEditUserForm" scope="request"/>
<c:set var="keyEnableLogoutAllSessions"><%=KEY_ENABLE_LOGOUT_ALL_SESSIONS%></c:set>
<div id="profilePage">
<form action="<c:url value='/admin/editUser.html?userId=${adminEditUserForm.userId}'/>" onsubmit="return BS.AdminUpdateUserForm.submitUserProfile()" method="post" autocomplete="off">
  <bs:messages key="<%=AdminEditUserController.USER_CHANGED_MESSAGES_KEY%>"/>
  <bs:messages key="<%=AdminEditUserController.USER_SESSIONS_TERMINATED%>"/>
  <bs:messages key="<%=EmailVerificationController.MESSAGE_KEY%>" permanent="${true}"/>

  <profile:general profileForm="${adminEditUserForm}" adminMode="true"/>
  <c:if test="${adminEditUserForm.canRemoveUserAccount}">
    <l:settingsBlock title="Security actions">
      <div class="general-property">
        <a class="link-secure-text-action" href="#" onclick="BS.AdminUpdateUserForm.deleteUserAccount(); return false">Delete user account</a>
      </div>
      <c:if test="${intprop:getBooleanOrTrue(keyEnableLogoutAllSessions)}">
        <div class="general-property">
          <a class="link-secure-text-action" href="#" onclick="BS.AdminUpdateUserForm.logoutAllUserSessions(); return false">Log out all user sessions</a>
        </div>
      </c:if>
    </l:settingsBlock>
    <div class="clr"></div>
  </c:if>
  <c:if test="${not adminEditUserForm.perProjectPermissionsEnabled}">
    <l:settingsBlock title="Administrator status">
      <admin:perProjectRolesNote/>
      <forms:checkbox name="administrator" checked="${adminEditUserForm.administrator}" disabled="${not adminEditUserForm.canEditPermissions or adminEditUserForm.administratorStatusInherited}"/>
      <label for="administrator">Give this user administrative privileges</label>
      <c:if test="${adminEditUserForm.administratorStatusInherited}">
        <bs:smallNote>Administrative privileges are inherited from one or more parent groups</bs:smallNote>
      </c:if>
    </l:settingsBlock>
  </c:if>
  <a name="<%=AdminEditUserController.AUTH_SETTINGS_ANCHOR%>"></a>
  <profile:userAuthSettings profileForm="${adminEditUserForm}"/>

  <c:if test="${!adminEditUserForm.readOnly}">
    <div class="saveButtonsBlock saveButtonsBlock_noborder">
      <forms:submit label="Save changes"/>
      <forms:cancel cameFromSupport="${adminEditUserForm.cameFromSupport}"/>
      <forms:saving id="saving1"/>
    </div>
  </c:if>

  <input type="hidden" id="submitUpdateUser" name="submitUpdateUser" value="storeInSession"/>
  <input type="hidden" name="userId" value="${adminEditUserForm.userId}"/>
  <input type="hidden" name="tab" value="${currentTab}"/>

</form>

<forms:modified/>
<script type="text/javascript">
  BS.AdminUpdateUserForm.setupEventHandlers();
  BS.AdminUpdateUserForm.setModified(${adminEditUserForm.stateModified});
</script>
</div>