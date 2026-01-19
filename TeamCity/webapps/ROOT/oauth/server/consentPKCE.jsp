<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="redirect_uri" type="java.lang.String" scope="request"/>
<jsp:useBean id="scope_list" type="java.util.Collection<jetbrains.buildServer.serverSide.auth.Permission>" scope="request"/>
<jsp:useBean id="scope" type="java.lang.String" scope="request"/>
<jsp:useBean id="state" type="java.lang.String" scope="request"/>
<jsp:useBean id="code_challenge" type="java.lang.String" scope="request"/>
<jsp:useBean id="code_challenge_method" type="java.lang.String" scope="request"/>
<jsp:useBean id="contextPath" type="java.lang.String" scope="request"/>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%>

<bs:linkCSS>
  /css/forms.css
  /css/maintenance-initialPages-common.css
  /css/initialPages.css
</bs:linkCSS>

<style>
  .auth-consent-form-permissions h4, .auth-consent-form-permissions ul li, .auth-consent-form-block h4 {
    text-align: justify;
    font-weight: normal;
  }

  h1#header {
    margin-top: 16px;
  }

</style>

<c:set var="title" value="OAuth 2.0 PKCE"/>
<bs:externalPage>
  <jsp:attribute name="page_title">OAuth 2.0 PKCE</jsp:attribute>
  <jsp:attribute name="body_include">
    <bs:_loginPageDecoration id="oauthPkcePage" title="${title}">
      <div class="auth-consent-form-block">
        <h4>
          An access token with these permissions for the <i>Root</i> project will be issued:
        </h4>
      </div>
      <div class="auth-consent-form-permissions">
          <ul>
            <c:forEach items="${scope_list}" var="permission">
              <li>
                <c:out value="${permission.description}"/>
              </li>
            </c:forEach>
          </ul>
      </div>
      <div class="auth-consent-form-block">
        <h4>
          If a user lacks any of these permissions, they will be omitted from the token. If a user has certain permissions limited to individual project rather than the entire <i>Root</i>, the token access permissions will match this setup.
        </h4>
      </div>

      <form action="${contextPath}/pkce/code.html" method="post">
        <input type="hidden" id="redirect_uri" name="redirect_uri" value="<c:out value="${redirect_uri}"/>">
        <input type="hidden" id="scope" name="scope" value="${scope}">
        <input type="hidden" id="state" name="state" value="<c:out value="${state}"/>">
        <input type="hidden" id="code_challenge" name="code_challenge" value="<c:out value="${code_challenge}"/>">
        <input type="hidden" id="code_challenge_method" name="code_challenge_method" value="<c:out value="${code_challenge_method}"/>">
        <input type="hidden" name="tc-csrf-token" value="${sessionScope['tc-csrf-token']}"/>
        <div class="buttons">
          <input class="btn loginButton btn_primary" type="submit" name="submitLogin" value="Confirm">
        </div>
      </form>
    </bs:_loginPageDecoration>
  </jsp:attribute>
</bs:externalPage>