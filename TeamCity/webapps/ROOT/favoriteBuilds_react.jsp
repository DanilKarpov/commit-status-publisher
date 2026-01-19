<%@ include file="include-internal.jsp" %>
<%--@elvariable id="bean" type="jetbrains.buildServer.controllers.builds.FavoriteBuildsBean"--%>
<jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"/>
<bs:page>
  <jsp:attribute name="page_title">Favorite Builds</jsp:attribute>
  <jsp:attribute name="head_include">
     <bs:linkCSS>
       /css/agentsInfoPopup.css
       /css/filePopup.css
     </bs:linkCSS>
     <bs:linkScript>
    </bs:linkScript>
    <script type="text/javascript">
      BS.Navigation.items = [
        {title: "Favorite Builds", selected: true}
      ];
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <bs:openInSakuraUI favoriteBuilds="${true}" />
    <bs:redirectToSakuraUI favoriteBuilds="${true}" />
    <bs:sakuraReleaseBanner favoriteBuilds="${true}" />
    <bs:pinBuildDialog onBuildPage="${false}"/>
    <div>On this page you can view your favorite builds.<bs:help file="AddBuildToFavorites"/></div>
    <div id="fb"></div>
    <script type="text/javascript">
      (function () {
        ReactUI.renderFavoriteBuilds('fb');
      })();
    </script>
  </jsp:attribute>

</bs:page>
