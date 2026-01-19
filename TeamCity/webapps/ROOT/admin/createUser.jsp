<%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="profile" tagdir="/WEB-INF/tags/userProfile"%>

<c:set var="currentTab" value=""/>
<c:set var="pageTitle" value="Create a New User Account" scope="request"/>
<bs:page>
<jsp:attribute name="head_include">

  <bs:linkCSS>
    /css/profilePage.css
    /css/settingsBlock.css
    /css/admin/adminMain.css
  </bs:linkCSS>
  <style type="text/css">
    div.createMoreUsers {
      padding-bottom:1em;
      padding-left:1em;
      float: left;
      width: 20em;
    }
  </style>
  <bs:linkScript>
    /js/bs/createUser.js
    /js/bs/profile.js
  </bs:linkScript>
  <script type="text/javascript">
    BS.Navigation.items = [
      {title: "Users", url: '<c:url value="/admin/admin.html?item=users"/>'},
      {title: "${pageTitle}", selected:true}
    ];
  </script>

</jsp:attribute>

<jsp:attribute name="body_include">

  <div id="container" class="clearfix">

    <bs:messages key="userCreated"/>
    <jsp:useBean id="adminCreateUserForm" type="jetbrains.buildServer.controllers.admin.users.AdminCreateUserForm" scope="request"/>

    <form action="<c:url value='/admin/createUserSubmit.html'/>" onsubmit="return BS.AdminCreateUserForm.submitCreateUser(
        ${adminCreateUserForm.canChangePassword && !adminCreateUserForm.passwordIsMandatory}
    )" method="post" autocomplete="off">

    <div id="profilePage">

      <profile:general profileForm="${adminCreateUserForm}" adminMode="true"/>
      <c:if test="${not adminCreateUserForm.perProjectPermissionsEnabled}">
        <l:settingsBlock title="Administrator status">
          <forms:checkbox name="administrator" checked="${adminCreateUserForm.administrator}"/> <label for="administrator">Give this user administrative privileges</label>
        </l:settingsBlock>
      </c:if>

      <profile:userAuthSettings profileForm="${adminCreateUserForm}"/>

      <div class="stayMessage">
        <forms:checkbox name="createMoreUsers" style="vertical-align:text-top;" checked="${adminCreateUserForm.createMoreUsers}"/>
        <label for="createMoreUsers">Stay on this page to create more users after submit</label>
      </div>


      <div class="saveButtonsBlock saveButtonsBlock_noborder">
        <forms:submit name="submitCreateUser" label="Create User"/>
        <forms:cancel cameFromSupport="${adminCreateUserForm.cameFrom}"/>
        <forms:saving id="saving1"/>
      </div>

    </div>

    </form>

    </div>
</jsp:attribute>

</bs:page>
