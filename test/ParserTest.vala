int main ()
{
    try
    {
        PseudoTerminal.parse ("t('~')");
        PseudoPaned.parse ("h(0.5;t('~')|t('~'))");
        PseudoPaned.parse ("h(0.5;t('~')|h(0.5;t('~')|t('~')))");
        PseudoPaned.parse ("h(0.5;h(0.5;v(0.5;v(0.5;t('~')|t('~'))|v(0.5;t('~')|t('~')))|v(0.5;v(0.5;t('~')|t('~'))|v(0.5;t('~')|t('~'))))|h(0.5;v(0.5;v(0.5;t('~')|t('~'))|v(0.5;t('~')|t('~')))|v(0.5;v(0.5;t('~')|t('~'))|v(0.5;t('~')|t('~')))))");
        PseudoWorkspace.parse ("w(t('~'))");
        PseudoWorkspace.parse ("w(h(0.5;h(0.5;v(0.5;v(0.5;t('~')|t('~'))|v(0.5;t('~')|t('~')))|v(0.5;v(0.5;t('~')|t('~'))|v(0.5;t('~')|t('~'))))|h(0.5;v(0.5;v(0.5;t('~')|t('~'))|v(0.5;t('~')|t('~')))|v(0.5;v(0.5;t('~')|t('~'))|v(0.5;t('~')|t('~'))))))");
    }
    catch (ParseError e)
    {
        print ("Quark: %s\n%s\n", e.domain.to_string(), e.message);
        return 1;
    }

    return 0;
}