<%@ include file="include-internal.jsp" %>
<jsp:useBean id="createAdminForm" type="jetbrains.buildServer.controllers.user.NewUserForm" scope="request"/>
<jsp:useBean id="nonDefaultLoginConfigured" type="java.lang.Boolean" scope="request"/>
<jsp:useBean id="rootLoginAllowed" type="java.lang.Boolean" scope="request"/>
<c:set var="title" value="Create Administrator Account"/>
<bs:externalPage>
  <jsp:attribute name="page_title">${title}</jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/forms.css
      /css/maintenance-initialPages-common.css
      /css/initialPages.css
    </bs:linkCSS>
    <bs:linkScript>
      /js/crypt/rsa.js
      /js/crypt/jsbn.js
      /js/crypt/prng4.js
      /js/crypt/rng.js
      /js/bs/forms.js
      /js/bs/encrypt.js
      /js/bs/createUser.js
    </bs:linkScript>
    <bs:reactUi />
    <script>
      ReactUI.serviceWorkers.cleanServiceWorkerCaches();
      localStorage.clear();
      ReactUI.setGlobalTheme();
    </script>
    <script type="text/javascript">
      $j(document).ready(function($) {
        $("#input_teamcityUsername").focus();
      });
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <bs:_loginPageDecoration id="createAdminPage" title="${title}">
        <form action="<c:url value='/createAdminSubmit.html'/>" onsubmit="return BS.CreateUserForm.submitCreateUser();" method="post">

          <div id="errorMessage"></div>

          <div>
            <label for="input_teamcityUsername">Username</label>
            <span class="input-wrapper input-wrapper_username"><input class="text" id="input_teamcityUsername" type="text" name="username1" size="25" maxlength="191" value="<c:out value='${createAdminForm.username1}'/>"></span>
          </div>
          <div>
            <label for="password1">Password</label>
            <span class="input-wrapper input-wrapper_password1"><input class="text" id="password1" type="password" name="password1" size="25"></span>
          </div>
          <div>
            <label for="retypedPassword">Confirm password</label>
            <span class="input-wrapper input-wrapper_retypedPassword"><input class="textField" id="retypedPassword" type="password" name="retypedPassword" size="30"
                                                                             autocomplete="new-password"/></span>
          </div>

          <div class="buttons">
            <forms:saving className="progressRingSubmitBlock progressRingCreateAdmin"/>
            <input class="btn loginButton" type="submit" value="Create Account"/>
          </div>

          <input type="hidden" id="submitCreateUser" name="submitCreateUser"/>
          <input type="hidden" id="publicKey" name="publicKey" value="${createAdminForm.hexEncodedPublicKey}"/>
        </form>

        <c:if test="${nonDefaultLoginConfigured || rootLoginAllowed}">
          <p class="registerUser">
            <span class="greyNote">
              <c:if test="${nonDefaultLoginConfigured}"><a href="<c:url value='/setupAdmin.html?init=1'/>">Set up administrator account</a></c:if>
              <c:if test="${nonDefaultLoginConfigured && rootLoginAllowed}">&nbsp;or&nbsp;</c:if>
              <c:if test="${rootLoginAllowed}"><a href="<c:url value='/login.html?super=1'/>">Login as Super user</a></c:if>
            </span>
          </p>
        </c:if>
    </bs:_loginPageDecoration>
  </jsp:attribute>
</bs:externalPage>

